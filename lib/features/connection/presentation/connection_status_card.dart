import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/modbus_error_text.dart';

class ConnectionStatusCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(connectionControllerProvider);
    final controller = ref.read(connectionControllerProvider.notifier);
    final time = DateFormat.Hms(Localizations.localeOf(context).toString());

    Widget errorFor(Object error) {
      final text = describeError(l10n, error);
      return ErrorPanel(
        title: text.title,
        hint: text.hint,
        detail: text.detail,
      );
    }

    final (icon, color, title, subtitle, body, actions) = switch (state) {
      Disconnected() => (
        Icons.link_off,
        theme.colorScheme.onSurfaceVariant,
        l10n.statusNotConnected,
        l10n.statusNotConnectedHint,
        null,
        <Widget>[],
      ),
      Connecting(:final profile, :final attempt, :final lastError) => (
        Icons.sync,
        context.appColors.warning,
        attempt > 0
            ? l10n.statusReconnecting(attempt)
            : l10n.statusConnectingTo(profile.name),
        profile.config.summary,
        lastError == null ? null : errorFor(lastError),
        <Widget>[
          OutlinedButton(
            onPressed: controller.disconnect,
            child: Text(l10n.actionCancel),
          ),
        ],
      ),
      Connected(:final profile, :final since, :final client) => (
        Icons.link,
        context.appColors.success,
        l10n.statusConnectedTo(profile.name),
        '${client.description} · ${profile.config.summary} · '
            '${l10n.statusSince(time.format(since))}',
        null,
        <Widget>[
          FilledButton.tonalIcon(
            onPressed: controller.disconnect,
            icon: const Icon(Icons.link_off),
            label: Text(l10n.actionDisconnect),
          ),
        ],
      ),
      ConnectionFailed(:final profile, :final error) => (
        Icons.error_outline,
        theme.colorScheme.error,
        l10n.statusFailed(profile.name),
        profile.config.summary,
        errorFor(error),
        <Widget>[
          TextButton(
            onPressed: controller.disconnect,
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () => controller.connect(profile),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.actionRetry),
          ),
        ],
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (state is Connecting)
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: color,
                    ),
                  )
                else
                  Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        subtitle,
                        // Monospace only for technical endpoint details,
                        // not for the plain "choose a profile" hint.
                        style:
                            (state is Disconnected
                                    ? theme.textTheme.bodySmall!
                                    : theme.textTheme.bodySmall!.mono)
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (body != null) ...[const SizedBox(height: 12), body],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
