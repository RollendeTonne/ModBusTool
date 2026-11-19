import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_kind_ui.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_status_card.dart';
import 'package:modbus_explorer/features/connection/presentation/profile_editor.dart';
import 'package:modbus_explorer/features/connection/presentation/profile_transfer.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/simulator/presentation/simulator_server_card.dart';

class ConnectionPage extends ConsumerWidget {
  const new({super.key});

  static const _twoColumnWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(platformCapabilitiesProvider);
    final sidePanels = [
      const ConnectionStatusCard(),
      if (caps.supportsLocalTcpServer) const SimulatorServerCard(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _twoColumnWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 3, child: _ProfilesPanel()),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: sidePanels,
                ),
              ),
            ],
          );
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverList.list(children: [sidePanels.first]),
            ),
            const _ProfilesSliver(),
            if (sidePanels.length > 1)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList.list(children: sidePanels.sublist(1)),
              ),
          ],
        );
      },
    );
  }
}

class _ProfilesPanel extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      const CustomScrollView(slivers: [_ProfilesSliver()]);
}

class _ProfilesSliver extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profiles = ref.watch(profilesControllerProvider);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.profilesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          FilledButton.icon(
            key: const Key('profiles.new'),
            onPressed: () => _createProfile(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.profileNew),
          ),
          PopupMenuButton<String>(
            key: const Key('profiles.transfer'),
            icon: const Icon(Icons.import_export),
            onSelected: (action) => action == 'import'
                ? importProfiles(context, ref)
                : exportProfiles(context, ref),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(l10n.actionImportProfiles),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(l10n.actionExportProfiles),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: header),
        switch (profiles) {
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.profilesEmpty, textAlign: TextAlign.center),
            ),
          ),
          AsyncData(:final value) => SliverList.builder(
            itemCount: value.length,
            itemBuilder: (context, i) => _ProfileTile(profile: value[i]),
          ),
          AsyncError(:final error) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$error'),
            ),
          ),
          _ => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        },
      ],
    );
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final profile = await showProfileEditor(context);
    if (profile != null) {
      await ref.read(profilesControllerProvider.notifier).save(profile);
    }
  }
}

enum _ProfileAction { edit, duplicate, delete }

class _ProfileTile extends ConsumerWidget {
  const new({required this.profile});

  final ConnectionProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final controller = ref.read(connectionControllerProvider.notifier);
    final isActive =
        connection.profile?.id == profile.id && connection is! ConnectionFailed;
    final lastUsed = profile.lastUsedAt;
    final format = DateFormat.yMd(Localizations.localeOf(context).toString())
        .add_Hm();

    return ListTile(
      key: ValueKey('profile.${profile.id}'),
      selected: isActive,
      leading: Icon(profile.config.kind.icon),
      title: Row(
        children: [
          Flexible(child: Text(profile.name, overflow: TextOverflow.ellipsis)),
          if (isActive) ...[
            const SizedBox(width: 8),
            Text(
              l10n.profileActive,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${profile.config.kind.label(l10n)} · ${profile.config.summary}',
            style: theme.textTheme.bodySmall!.mono,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            lastUsed == null
                ? l10n.profileNeverUsed
                : l10n.profileLastUsed(format.format(lastUsed)),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => _edit(context, ref),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            OutlinedButton(
              onPressed: controller.disconnect,
              child: Text(l10n.actionDisconnect),
            )
          else
            FilledButton.tonal(
              key: ValueKey('profile.${profile.id}.connect'),
              onPressed: () => controller.connect(profile),
              child: Text(l10n.actionConnect),
            ),
          PopupMenuButton<_ProfileAction>(
            onSelected: (action) => switch (action) {
              _ProfileAction.edit => _edit(context, ref),
              _ProfileAction.duplicate => _duplicate(context, ref),
              _ProfileAction.delete => _delete(context, ref),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ProfileAction.edit,
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.actionEdit),
                ),
              ),
              PopupMenuItem(
                value: _ProfileAction.duplicate,
                child: ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: Text(l10n.actionDuplicate),
                ),
              ),
              PopupMenuItem(
                value: _ProfileAction.delete,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.actionDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final updated = await showProfileEditor(context, initial: profile);
    if (updated != null) {
      await ref.read(profilesControllerProvider.notifier).save(updated);
    }
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    await ref
        .read(profilesControllerProvider.notifier)
        .duplicate(profile, name: context.l10n.profileCopyName(profile.name));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteBody(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (ref.read(connectionControllerProvider).profile?.id == profile.id) {
      unawaited(ref.read(connectionControllerProvider.notifier).disconnect());
    }
    await ref.read(profilesControllerProvider.notifier).delete(profile.id);
  }
}
