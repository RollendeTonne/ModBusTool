import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profile_editor.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';

/// Subscriptions of the connected profile: toggle, remove, add.
class MqttSubscriptionsPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MqttSubscriptionsPanel> createState() =>
      _MqttSubscriptionsPanelState();
}

class _MqttSubscriptionsPanelState
    extends ConsumerState<MqttSubscriptionsPanel> {
  final _filter = TextEditingController();
  MqttQosLevel _qos = MqttQosLevel.atMostOnce;
  bool _noLocal = false;
  bool _retainAsPublished = false;
  MqttRetainHandling _retainHandling = MqttRetainHandling.sendOnSubscribe;
  String? _error;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  MqttConnectionController get _controller =>
      ref.read(mqttConnectionControllerProvider.notifier);

  Future<void> _add([String? filter]) async {
    final text = (filter ?? _filter.text).trim();
    final error = topicErrorText(context.l10n, validateTopicFilter(text));
    setState(() => _error = error);
    if (error != null) return;
    if (text == '#' && !await _confirmSubscribeAll()) return;
    await _controller.putSubscription(
      MqttSubscriptionSpec(
        filter: text,
        qos: _qos,
        noLocal: _noLocal,
        retainAsPublished: _retainAsPublished,
        retainHandling: _retainHandling,
      ),
    );
    if (mounted && filter == null) _filter.clear();
  }

  Future<bool> _confirmSubscribeAll() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(l10n.mqttSubscribeAll),
        content: Text(l10n.mqttSubscribeAllWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('mqtt.subscribeAllConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.mqttSubscribeAllConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final state = ref.watch(mqttConnectionControllerProvider);
    final profile = state.profile;
    final enabled = profile != null;
    final v5 = profile?.config.protocolVersion == MqttProtocolVersion.v5;
    final subscriptions = profile?.config.subscriptions ?? const [];

    return Card(
      key: const Key('mqtt.subscriptions'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mqttSubscriptions, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.mqttNoSubscriptions),
              ),
            for (final s in subscriptions)
              Row(
                key: Key('mqtt.sub.${s.filter}'),
                children: [
                  Switch(
                    value: s.enabled,
                    onChanged: (v) =>
                        _controller.putSubscription(s.copyWith(enabled: v)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.filter,
                      style: mono.copyWith(
                        color: s.enabled
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('QoS ${s.qos.value}', style: theme.textTheme.labelSmall),
                  IconButton(
                    key: Key('mqtt.sub.delete.${s.filter}'),
                    tooltip: l10n.mqttDeleteSubscription,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _controller.removeSubscription(s.filter),
                  ),
                ],
              ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('mqtt.sub.filter'),
                    controller: _filter,
                    enabled: enabled,
                    style: mono,
                    decoration: InputDecoration(
                      labelText: l10n.mqttTopicFilter,
                      hintText: l10n.mqttTopicFilterHint,
                      errorText: _error,
                      errorMaxLines: 2,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                QosDropdown(
                  value: _qos,
                  onChanged: enabled ? (q) => setState(() => _qos = q) : null,
                ),
              ],
            ),
            if (v5)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.mqttMqtt5Options),
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.mqttNoLocal),
                    value: _noLocal,
                    onChanged: (v) => setState(() => _noLocal = v!),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.mqttRetainAsPublished),
                    value: _retainAsPublished,
                    onChanged: (v) => setState(() => _retainAsPublished = v!),
                  ),
                  DropdownButtonFormField<MqttRetainHandling>(
                    initialValue: _retainHandling,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.mqttRetainHandling,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: MqttRetainHandling.sendOnSubscribe,
                        child: Text(l10n.mqttRetainSend),
                      ),
                      DropdownMenuItem(
                        value: MqttRetainHandling.sendIfNewSubscription,
                        child: Text(l10n.mqttRetainSendIfNew),
                      ),
                      DropdownMenuItem(
                        value: MqttRetainHandling.doNotSend,
                        child: Text(l10n.mqttRetainDont),
                      ),
                    ],
                    onChanged: (v) => setState(() => _retainHandling = v!),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('mqtt.sub.add'),
                  onPressed: enabled ? _add : null,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.mqttAddSubscription),
                ),
                TextButton.icon(
                  key: const Key('mqtt.sub.all'),
                  onPressed: enabled ? () => _add('#') : null,
                  icon: const Icon(Icons.all_inclusive),
                  label: Text(l10n.mqttSubscribeAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
