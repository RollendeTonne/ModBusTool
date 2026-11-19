import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profile_editor.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profiles_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';

/// Broker status on top, profile list below.
class MqttConnectionPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profiles = ref.watch(mqttProfilesControllerProvider);

    return ListView(
      key: const Key('mqtt.connectionPage'),
      padding: const EdgeInsets.all(12),
      children: [
        const _StatusCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mqttProfiles,
                style: theme.textTheme.titleMedium,
              ),
            ),
            FilledButton.tonalIcon(
              key: const Key('mqtt.profiles.new'),
              onPressed: () => showMqttProfileEditor(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.mqttNewProfile),
            ),
          ],
        ),
        const SizedBox(height: 8),
        switch (profiles) {
          AsyncData(:final value) when value.isEmpty => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.mqttNoProfiles, textAlign: TextAlign.center),
          ),
          AsyncData(:final value) => Column(
            children: [for (final p in value) _ProfileTile(profile: p)],
          ),
          AsyncError(:final error) => Text('$error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(mqttConnectionControllerProvider);
    final controller = ref.read(mqttConnectionControllerProvider.notifier);
    final (label, icon, color) = mqttStatusLook(context, state.status);
    final profile = state.profile;
    final failure = state.failure;

    return Card(
      key: const Key('mqtt.statusCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile == null ? label : '$label · ${profile.name}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (state.isActive)
                  OutlinedButton.icon(
                    key: const Key('mqtt.disconnect'),
                    onPressed: controller.disconnect,
                    icon: const Icon(Icons.link_off),
                    label: Text(
                      state.status == MqttConnectionStatus.reconnecting
                          ? l10n.mqttCancelReconnect
                          : l10n.mqttDisconnect,
                    ),
                  )
                else if (profile != null)
                  FilledButton.tonalIcon(
                    key: const Key('mqtt.reconnect'),
                    onPressed: () => controller.connect(profile),
                    icon: const Icon(Icons.link),
                    label: Text(l10n.mqttConnect),
                  ),
              ],
            ),
            if (profile != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                [
                  if (profile.config.simulated)
                    l10n.mqttSimulatorBadge
                  else ...[
                    profile.config.endpoint,
                    transportLabel(profile.config.transport),
                  ],
                  'MQTT ${versionLabel(profile.config.protocolVersion)}',
                  if (state.clientId != null)
                    l10n.mqttClientIdLabel(state.clientId!),
                ].join(' · '),
                style: theme.textTheme.bodySmall!.mono,
              ),
            ],
            if (failure != null && profile != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('mqtt.failure'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mqttFailureText(
                          l10n,
                          failure,
                          profile.config.protocolVersion,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (failure.detail case final detail?)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SelectableText(
                            detail,
                            style: theme.textTheme.bodySmall!.mono.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      if (state.status == MqttConnectionStatus.reconnecting &&
                          state.nextRetryAt != null)
                        _RetryCountdown(
                          attempt: state.reconnectAttempt,
                          at: state.nextRetryAt!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetryCountdown extends StatefulWidget {
  const new({required this.attempt, required this.at});

  final int attempt;
  final DateTime at;

  @override
  State<_RetryCountdown> createState() => _RetryCountdownState();
}

class _RetryCountdownState extends State<_RetryCountdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.at
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 999);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(context.l10n.mqttReconnectIn(widget.attempt, seconds)),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const new({required this.profile});

  final MqttProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(mqttConnectionControllerProvider);
    final controller = ref.read(mqttConnectionControllerProvider.notifier);
    final profiles = ref.read(mqttProfilesControllerProvider.notifier);
    final isCurrent = state.profile?.id == profile.id && state.isActive;
    final c = profile.config;

    Future<void> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.mqttDeleteProfileTitle),
          content: Text(l10n.mqttDeleteProfileText(profile.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const Key('mqtt.deleteConfirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.actionDelete),
            ),
          ],
        ),
      );
      if (ok ?? false) {
        if (isCurrent) await controller.disconnect();
        await profiles.delete(profile.id);
      }
    }

    return Card.outlined(
      key: Key('mqtt.profile.${profile.id}'),
      child: ListTile(
        leading: Icon(
          c.simulated
              ? Icons.science_outlined
              : c.transport.secure
              ? Icons.lock_outline
              : Icons.dns_outlined,
        ),
        title: Text(profile.name),
        subtitle: Text(
          [
            if (c.simulated) l10n.mqttSimulatorBadge else c.endpoint,
            if (!c.simulated) transportLabel(c.transport),
            'MQTT ${versionLabel(c.protocolVersion)}',
          ].join(' · '),
          style: theme.textTheme.bodySmall!.mono,
        ),
        onTap: isCurrent ? null : () => controller.connect(profile),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent)
              Icon(Icons.check_circle, color: theme.colorScheme.primary)
            else
              IconButton(
                key: Key('mqtt.connect.${profile.id}'),
                tooltip: l10n.mqttConnect,
                icon: const Icon(Icons.link),
                onPressed: () => controller.connect(profile),
              ),
            PopupMenuButton<String>(
              key: Key('mqtt.menu.${profile.id}'),
              onSelected: (action) async {
                switch (action) {
                  case 'edit':
                    await showMqttProfileEditor(context, ref, initial: profile);
                  case 'duplicate':
                    await profiles.duplicate(
                      profile,
                      name: l10n.mqttProfileCopy(profile.name),
                    );
                  case 'delete':
                    await confirmDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.actionDuplicate),
                ),
                PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
