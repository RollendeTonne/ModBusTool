import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/trend_controller.dart';

class TrendView extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = ref
        .watch(currentMapEntriesProvider)
        .where((e) => e.format is NumericFormat)
        .toList();
    final trend = ref.watch(trendControllerProvider);
    final controller = ref.read(trendControllerProvider.notifier);
    final polling = ref.watch(
      mapValuesControllerProvider.select((s) => s.isPolling),
    );
    final connected = ref.watch(activeClientProvider) != null;
    final palette = [
      theme.colorScheme.primary,
      context.appColors.rx,
      context.appColors.warning,
      context.appColors.success,
    ];
    final selected = [
      for (final id in trend.selected)
        if (entries.any((e) => e.id == id)) id,
    ];

    final series = <LineChartBarData>[];
    DateTime? start;
    for (final id in selected) {
      final first = trend.series[id]?.firstOrNull?.time;
      if (first != null && (start == null || first.isBefore(start))) {
        start = first;
      }
    }
    for (final id in selected) {
      final points = trend.series[id] ?? const [];
      if (points.isEmpty || start == null) continue;
      series.add(
        LineChartBarData(
          spots: [
            for (final p in points)
              FlSpot(p.time.difference(start).inMilliseconds / 1000, p.value),
          ],
          color: palette[trend.selected.indexOf(id) % palette.length],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return ListView(
      key: const Key('trend.view'),
      padding: const EdgeInsets.all(12),
      children: [
        if (entries.isEmpty)
          Text(l10n.trendNoEntries)
        else ...[
          Text(
            l10n.trendSelect(TrendController.maxSeries),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in entries)
                FilterChip(
                  key: ValueKey('trend.entry.${e.id}'),
                  label: Text(e.label.isEmpty ? l10n.mapUnnamed : e.label),
                  avatar: trend.selected.contains(e.id)
                      ? CircleAvatar(
                          backgroundColor:
                              palette[trend.selected.indexOf(e.id) %
                                  palette.length],
                        )
                      : null,
                  showCheckmark: false,
                  selected: trend.selected.contains(e.id),
                  onSelected: (_) {
                    if (!controller.toggle(e.id)) {
                      ScaffoldMessenger.of(context).showReplacing(
                        l10n.trendMaxReached(TrendController.maxSeries),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const Key('trend.poll'),
                onPressed: connected || polling
                    ? ref
                          .read(mapValuesControllerProvider.notifier)
                          .togglePolling
                    : null,
                icon: Icon(polling ? Icons.stop : Icons.play_arrow),
                label: Text(
                  polling ? l10n.actionStopPolling : l10n.trendPollMap,
                ),
              ),
              OutlinedButton(
                onPressed: controller.clear,
                child: Text(l10n.monitorClear),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (series.isEmpty)
            Text(l10n.trendWaiting)
          else
            SizedBox(
              height: 320,
              child: Semantics(
                label: l10n.toolsTrend,
                child: LineChart(
                  key: const Key('trend.chart'),
                  LineChartData(
                    lineBarsData: series,
                    gridData: FlGridData(
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 0.5,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${value.toStringAsFixed(0)} s',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  duration: Duration.zero,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
