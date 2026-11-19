import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_status.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_status_provider.dart';

class ConnectionStatusChip extends ConsumerWidget {
  const new({this.compact = false, super.key});

  /// Icon only (phones, next to the module switcher); the label stays in
  /// the tooltip and for screen readers.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final (label, icon, color) = switch (status) {
      ConnectionStatus.disconnected => (
        l10n.connectionStatusDisconnected,
        Icons.link_off,
        scheme.onSurfaceVariant,
      ),
      ConnectionStatus.connecting => (
        l10n.connectionStatusConnecting,
        Icons.sync,
        colors.warning,
      ),
      ConnectionStatus.connected => (
        l10n.connectionStatusConnected,
        Icons.link,
        colors.success,
      ),
      ConnectionStatus.error => (
        l10n.connectionStatusError,
        Icons.error_outline,
        scheme.error,
      ),
    };

    // Icon + text rather than colour alone, so the state is readable for
    // colour-blind users and screen readers.
    return Semantics(
      label: l10n.connectionStatusLabel(label),
      button: true,
      excludeSemantics: true,
      child: compact
          ? IconButton(
              tooltip: label,
              icon: Icon(icon, color: color),
              onPressed: () => context.go(AppDestination.modbusConnection.path),
            )
          : ActionChip(
              avatar: Icon(icon, size: 18, color: color),
              label: Text(label),
              side: BorderSide(color: color),
              onPressed: () => context.go(AppDestination.modbusConnection.path),
            ),
    );
  }
}
