import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/registers/presentation/register_table.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/registers/presentation/request_panel.dart';
import 'package:modbus_explorer/features/registers/presentation/write_dialogs.dart';

class RegistersPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(registersControllerProvider);
    final controller = ref.read(registersControllerProvider.notifier);
    final connected = ref.watch(activeClientProvider) != null;
    final snapshot = state.snapshot;
    final error = state.lastError;
    final time = DateFormat.Hms(Localizations.localeOf(context).toString());

    void read() {
      if (connected && !state.isPolling) unawaited(controller.read());
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): read,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): read,
        const SingleActivator(LogicalKeyboardKey.f5): read,
      },
      child: Focus(
        autofocus: true,
        child: CustomScrollView(
          slivers: [
            SliverList.list(
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (snapshot != null)
                              l10n.readStatus(
                                snapshot.count,
                                snapshot.latency?.inMilliseconds ?? 0,
                                time.format(snapshot.readAt),
                              ),
                            if (state.isPolling)
                              l10n.pollStatus(
                                state.readCount,
                                state.errorCount,
                              ),
                          ].join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                ),
              ],
            ),
            if (snapshot == null)
              SliverFillRemaining(
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
            else
              RegisterTableSliver(snapshot: snapshot),
          ],
        ),
      ),
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
