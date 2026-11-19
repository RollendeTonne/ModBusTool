import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/core/widgets/resizable_split.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/interpretation_panel.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_view.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/request_panel.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/write_dialogs.dart';

class RegistersPage extends ConsumerWidget {
  const new({super.key});

  /// The split layout needs room for the fixed request panel on top.
  static const _minSplitHeight = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(registersControllerProvider);
    final controller = ref.read(registersControllerProvider.notifier);
    final connected = ref.watch(activeClientProvider) != null;
    final snapshot = state.snapshot;

    final isMapView = state.view == RegistersView.map;
    final mapValues = ref.read(mapValuesControllerProvider.notifier);

    // In the map view the shortcuts act on the register map.
    void read() {
      if (!connected) return;
      if (isMapView) {
        if (!ref.read(mapValuesControllerProvider).isPolling) {
          unawaited(mapValues.read());
        }
      } else if (!state.isPolling) {
        unawaited(controller.read());
      }
    }

    void togglePolling() {
      if (!connected && !state.isPolling) return;
      isMapView ? mapValues.togglePolling() : controller.togglePolling();
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): read,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): read,
        const SingleActivator(LogicalKeyboardKey.f5): read,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            togglePolling,
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true):
            togglePolling,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final split =
                constraints.maxWidth >= interpretationSplitWidth &&
                constraints.maxHeight >= _minSplitHeight;
            final isMap = state.view == RegistersView.map;

            Widget tableSliver() => snapshot == null
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.registersEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : RegisterTableSliver(
                    snapshot: snapshot,
                    onRowSelected: split || snapshot.table.isBitTable
                        ? null
                        : (_) => showInterpretationSheet(context),
                  );

            final top = _TopSection(showInterpretButton: !split);

            if (!split) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: top),
                  if (isMap) const RegisterMapSliver() else tableSliver(),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                top,
                Expanded(
                  child: isMap
                      ? const CustomScrollView(slivers: [RegisterMapSliver()])
                      : ResizableSplit(
                          initialFraction: 0.45,
                          minFirst: 420,
                          minSecond: 480,
                          semanticLabel: l10n.interpretationTitle,
                          first: CustomScrollView(slivers: [tableSliver()]),
                          second: const InterpretationPanel(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Request panel, connection banner, errors, status line and view switch.
class _TopSection extends ConsumerWidget {
  const new({required this.showInterpretButton});

  final bool showInterpretButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(registersControllerProvider);
    final controller = ref.read(registersControllerProvider.notifier);
    final connected = ref.watch(activeClientProvider) != null;
    final mapCount = ref.watch(currentMapEntriesProvider).length;
    final snapshot = state.snapshot;
    final error = state.lastError;
    final time = DateFormat.Hms(Localizations.localeOf(context).toString());
    final isRaw = state.view == RegistersView.raw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const RequestPanel(),
        if (!connected) const _NotConnectedBanner(),
        if (error != null && error is! NotConnectedError)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Builder(
              builder: (context) {
                final text = describeError(l10n, error);
                return ErrorPanel(
                  key: const Key('registers.error'),
                  title: text.title,
                  hint: text.hint,
                  detail: text.detail,
                  dense: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: controller.clearError,
                    ),
                  ],
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SegmentedButton<RegistersView>(
                key: const Key('registers.view'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: RegistersView.raw,
                    icon: const Icon(Icons.table_rows_outlined),
                    label: Text(l10n.viewRaw),
                  ),
                  ButtonSegment(
                    value: RegistersView.map,
                    icon: const Icon(Icons.bookmarks_outlined),
                    label: Text(l10n.viewMap(mapCount)),
                  ),
                ],
                selected: {state.view},
                onSelectionChanged: (s) => controller.setView(s.single),
              ),
              if (isRaw)
                Text(
                  [
                    if (snapshot != null)
                      l10n.readStatus(
                        snapshot.count,
                        snapshot.latency?.inMilliseconds ?? 0,
                        time.format(snapshot.readAt),
                      ),
                    if (state.isPolling)
                      l10n.pollStatus(state.readCount, state.errorCount),
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (isRaw)
                Wrap(
                  spacing: 4,
                  children: [
                    if (showInterpretButton &&
                        snapshot != null &&
                        !snapshot.table.isBitTable)
                      TextButton.icon(
                        key: const Key('registers.interpret'),
                        onPressed: () => showInterpretationSheet(context),
                        icon: const Icon(Icons.functions),
                        label: Text(l10n.actionInterpret),
                      ),
                    if (state.query.table.isWritable)
                      TextButton.icon(
                        key: const Key('registers.writeMultiple'),
                        onPressed: connected && state.writeUnlocked
                            ? () => _writeMultiple(context, ref)
                            : null,
                        icon: const Icon(Icons.edit_note),
                        label: Text(l10n.actionWriteMultiple),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _writeMultiple(BuildContext context, WidgetRef ref) async {
    final query = ref.read(registersControllerProvider).query;
    final request = await showWriteMultipleDialog(
      context,
      ref,
      table: query.table,
      startAddress: query.address,
    );
    if (request != null && context.mounted) {
      await performWrite(context, ref, request);
    }
  }
}

class _NotConnectedBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.link_off, color: theme.colorScheme.onSecondaryContainer),
            Text(
              '${l10n.errorNotConnectedTitle} – ${l10n.errorNotConnectedHint}',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppDestination.connection.path),
              child: Text(l10n.actionOpenConnections),
            ),
            FilledButton.tonal(
              key: const Key('registers.connectSimulator'),
              onPressed: () => _connectSimulator(ref),
              child: Text(l10n.actionConnectSimulator),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectSimulator(WidgetRef ref) async {
    final profiles = await ref.read(profilesControllerProvider.future);
    var profile = profiles
        .where((p) => p.config.kind == ConnectionKind.simulator)
        .firstOrNull;
    if (profile == null) {
      profile = ConnectionProfile(
        id: ProfilesController.newProfileId(),
        name: 'Simulator (Demo)',
        config: const SimulatorConnectionConfig(),
        createdAt: DateTime.now(),
      );
      await ref.read(profilesControllerProvider.notifier).save(profile);
    }
    await ref.read(connectionControllerProvider.notifier).connect(profile);
  }
}
