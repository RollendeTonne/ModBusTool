import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/modbus/monitor/presentation/communication_log_controller.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

class StatisticsView extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stats = ref.watch(statisticsControllerProvider);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.yMd(locale).add_Hms();
    final percent = NumberFormat.percentPattern(locale)
      ..maximumFractionDigits = 1;
    String ms(Duration? d) => d == null
        ? ValueFormatter.invalidPlaceholder
        : '${d.inMilliseconds} ms';

    final tiles = [
      (l10n.statsRequests, '${stats.requests}'),
      (l10n.statsErrors, '${stats.errors}'),
      (l10n.statsErrorRate, percent.format(stats.errorRate)),
      (l10n.statsLatencyAvg, ms(stats.latencyAverage)),
      (l10n.statsLatencyMin, ms(stats.latencyMin)),
      (l10n.statsLatencyMax, ms(stats.latencyMax)),
      (l10n.statsTimeouts, '${stats.timeouts}'),
      (l10n.statsExceptions, '${stats.deviceExceptions}'),
      (l10n.statsProtocolErrors, '${stats.protocolErrors}'),
      (l10n.statsConnectionErrors, '${stats.connectionErrors}'),
      (l10n.statsRetries, '${stats.retries}'),
    ];

    return ListView(
      key: const Key('statistics.view'),
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.statsSince(time.format(stats.since)),
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              key: const Key('statistics.reset'),
              onPressed: ref.read(statisticsControllerProvider.notifier).reset,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.actionReset),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (stats.requests == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.statsEmpty),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: 168,
                child: Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: theme.textTheme.headlineSmall!.mono,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (stats.byFunction.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.statsByFunction, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 36,
            columns: [
              DataColumn(label: Text(l10n.segmentFunctionCode)),
              DataColumn(label: Text(l10n.statsRequests), numeric: true),
              DataColumn(label: Text(l10n.statsErrors), numeric: true),
            ],
            rows: [
              for (final MapEntry(key: fc, value: s)
                  in stats.byFunction.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                DataRow(
                  cells: [
                    DataCell(Text(fc, style: theme.textTheme.bodyMedium!.mono)),
                    DataCell(Text('${s.requests}')),
                    DataCell(Text('${s.errors}')),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}
