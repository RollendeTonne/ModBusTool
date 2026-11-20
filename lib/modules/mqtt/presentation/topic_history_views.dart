import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_diff.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_statistics.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

String clockTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
      '${t.millisecond.toString().padLeft(3, '0')}';
}

/// Newest first; a tap shows that message in the payload view.
class TopicHistoryList extends StatelessWidget {
  const new({
    required this.node,
    required this.perTopicLimit,
    required this.viewed,
    required this.onView,
    super.key,
  });

  final TopicNode node;
  final int perTopicLimit;
  final MqttMessageRecord? viewed;
  final ValueChanged<MqttMessageRecord> onView;

  /// Rows rendered inline (the parent scrolls, no virtualization here).
  static const maxRows = 500;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final history = node.history.toList().reversed.toList();
    if (history.isEmpty) return Text(l10n.historyEmpty);
    final mono = theme.textTheme.bodySmall!.mono;
    return Column(
      key: const Key('topic.history'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyCount(history.length, perTopicLimit),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        for (final (i, r) in history.take(maxRows).indexed)
          ListTile(
            key: Key('topic.history.$i'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            selected: identical(r, viewed) || (viewed == null && i == 0),
            leading: Text(clockTime(r.timestamp), style: mono),
            title: Text(
              payloadPreview(r.payload, maxChars: 60),
              style: mono,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              [
                if (i == 0) l10n.historyLatest,
                l10n.mqttBytes(r.payload.length),
                if (r.retain) 'R',
              ].join(' · '),
              style: theme.textTheme.labelSmall,
            ),
            onTap: () => onView(r),
          ),
      ],
    );
  }
}

/// Two history entries side by side: JSON structurally, text by line,
/// otherwise byte runs.
class TopicDiffView extends StatefulWidget {
  const new({required this.node, super.key});

  final TopicNode node;

  @override
  State<TopicDiffView> createState() => _TopicDiffViewState();
}

class _TopicDiffViewState extends State<TopicDiffView> {
  /// Picked entries; `null` = previous / latest (follows new messages).
  MqttMessageRecord? _old;
  MqttMessageRecord? _new;

  @override
  void didUpdateWidget(TopicDiffView old) {
    super.didUpdateWidget(old);
    if (old.node != widget.node) {
      _old = null;
      _new = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final history = widget.node.history.toList();
    if (history.length < 2) return Text(l10n.diffNeedTwo);
    // Picks that fell out of the history revert to the defaults.
    final a = _old != null && history.any((r) => identical(r, _old))
        ? _old!
        : history[history.length - 2];
    final b = _new != null && history.any((r) => identical(r, _new))
        ? _new!
        : history.last;

    DropdownButton<MqttMessageRecord> picker(
      Key key,
      MqttMessageRecord value,
      ValueChanged<MqttMessageRecord> onChanged,
    ) => DropdownButton<MqttMessageRecord>(
      key: key,
      value: value,
      isExpanded: true,
      items: [
        for (final r in history.reversed)
          DropdownMenuItem(
            value: r,
            child: Text(
              [
                clockTime(r.timestamp),
                payloadPreview(r.payload, maxChars: 30),
              ].join('  '),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall!.mono,
            ),
          ),
      ],
      onChanged: (r) => onChanged(r!),
    );

    return Column(
      key: const Key('topic.diff'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 48, child: Text(l10n.diffOld)),
            Expanded(
              child: picker(
                const Key('topic.diff.old'),
                a,
                (r) => setState(() => _old = r),
              ),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(width: 48, child: Text(l10n.diffNew)),
            Expanded(
              child: picker(
                const Key('topic.diff.new'),
                b,
                (r) => setState(() => _new = r),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('topic.diff.swap'),
            onPressed: () => setState(() {
              _old = b;
              _new = a;
            }),
            icon: const Icon(Icons.swap_vert),
            label: Text(l10n.diffSwap),
          ),
        ),
        const SizedBox(height: 8),
        _DiffResult(before: a, after: b),
      ],
    );
  }
}

class _DiffResult extends StatelessWidget {
  const new({required this.before, required this.after});

  final MqttMessageRecord before;
  final MqttMessageRecord after;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final mono = theme.textTheme.bodyMedium!.mono;
    final added = colors.success;
    final removed = theme.colorScheme.error;

    String show(Object? v) => v is String ? '"$v"' : jsonEncode(v);

    switch (diffModeFor(before.payload, after.payload)) {
      case DiffMode.json:
        final changes = diffJson(
          analyzeCached(before.payload).json,
          analyzeCached(after.payload).json,
        );
        return Column(
          key: const Key('topic.diff.json'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diffModeJson(changes.length),
              style: theme.textTheme.titleSmall,
            ),
            if (changes.isEmpty) Text(l10n.diffNoChanges),
            for (final c in changes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (c.kind) {
                        ChangeKind.added => Icons.add_circle_outline,
                        ChangeKind.removed => Icons.remove_circle_outline,
                        ChangeKind.changed => Icons.change_circle_outlined,
                      },
                      size: 18,
                      color: switch (c.kind) {
                        ChangeKind.added => added,
                        ChangeKind.removed => removed,
                        ChangeKind.changed => colors.warning,
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SelectableText(switch (c.kind) {
                        ChangeKind.added =>
                          '${c.pathText}  ${l10n.diffAdded}: ${show(c.after)}',
                        ChangeKind.removed =>
                          '${c.pathText}  '
                              '${l10n.diffRemoved}: ${show(c.before)}',
                        ChangeKind.changed =>
                          '${c.pathText}  ${show(c.before)} → ${show(c.after)}',
                      }, style: mono),
                    ),
                  ],
                ),
              ),
          ],
        );
      case DiffMode.text:
        final lines = diffLines(
          analyzeCached(before.payload).text ?? '',
          analyzeCached(after.payload).text ?? '',
        );
        final changed = lines.any((l) => l.op != LineOp.same);
        return Column(
          key: const Key('topic.diff.text'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.diffModeText, style: theme.textTheme.titleSmall),
            if (!changed) Text(l10n.diffNoChanges),
            if (changed)
              for (final line in lines.take(2000))
                Container(
                  width: double.infinity,
                  color: switch (line.op) {
                    LineOp.same => null,
                    LineOp.added => added.withValues(alpha: 0.15),
                    LineOp.removed => removed.withValues(alpha: 0.15),
                  },
                  child: Text(
                    '${switch (line.op) {
                      LineOp.same => ' ',
                      LineOp.added => '+',
                      LineOp.removed => '-',
                    }} ${line.text}',
                    style: mono,
                  ),
                ),
          ],
        );
      case DiffMode.bytes:
        final runs = diffBytes(before.payload, after.payload);
        return Column(
          key: const Key('topic.diff.bytes'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diffModeBytes(runs.length),
              style: theme.textTheme.titleSmall,
            ),
            if (runs.isEmpty) Text(l10n.diffNoChanges),
            for (final run in runs)
              SelectableText(
                l10n.diffByteRun(
                  run.offset,
                  run.before.isEmpty ? '–' : formatHexBytes(run.before),
                  run.after.isEmpty ? '–' : formatHexBytes(run.after),
                ),
                style: mono,
              ),
          ],
        );
    }
  }
}

/// Numeric value of the chosen field over the history (fl_chart).
class TopicChartView extends StatelessWidget {
  const new({
    required this.node,
    required this.field,
    required this.onClear,
    super.key,
  });

  final TopicNode node;
  final ChartField? field;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final field = this.field;
    if (field == null) {
      return Text(l10n.chartNoField, key: const Key('topic.chart.hint'));
    }
    final points = chartSeries(node.history, field);
    final header = Row(
      children: [
        Expanded(
          child: Text(
            l10n.chartField(field.label),
            key: const Key('topic.chart.field'),
            style: theme.textTheme.bodyMedium!.mono,
          ),
        ),
        IconButton(
          key: const Key('topic.chart.clear'),
          tooltip: l10n.chartClear,
          icon: const Icon(Icons.close),
          onPressed: onClear,
        ),
      ],
    );
    if (points.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, Text(l10n.chartNoPoints)],
      );
    }
    final values = points.map((p) => p.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final start = points.first.time;
    // Six significant digits: averages otherwise show binary noise.
    String fmt(double v) => ValueFormatter.formatScaled(
      double.parse(v.toStringAsPrecision(6)),
      null,
    );
    final spots = [
      for (final p in points)
        FlSpot(p.time.difference(start).inMilliseconds / 1000, p.value),
    ];

    return Column(
      key: const Key('topic.chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Text(
          l10n.chartSummary(
            points.length,
            fmt(minValue),
            fmt(maxValue),
            fmt(avg),
            fmt(values.last),
          ),
          key: const Key('topic.chart.summary'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: Semantics(
            label: l10n.topicTabChart,
            child: LineChart(
              LineChartData(
                // Flat series still get a visible band.
                minY: minValue == maxValue ? minValue - 1 : null,
                maxY: minValue == maxValue ? maxValue + 1 : null,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: theme.colorScheme.primary,
                    barWidth: 2,
                    dotData: FlDotData(show: spots.length <= 60),
                  ),
                ],
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
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${clockTime(_at(start, s.x))}\n${fmt(s.y)}',
                          theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 56),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        // The end label would collide with the last
                        // regular one ("55 s56 s").
                        final offGrid =
                            value == meta.max &&
                            value % meta.appliedInterval != 0;
                        if (offGrid) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toStringAsFixed(0)} s',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              duration: Duration.zero,
            ),
          ),
        ),
      ],
    );
  }
}

DateTime _at(DateTime start, double seconds) =>
    start.add(Duration(milliseconds: (seconds * 1000).round()));

/// Rate, sizes and age of a topic; the age ticks every second.
class TopicStatsView extends StatefulWidget {
  const new({required this.node, required this.tree, super.key});

  final TopicNode node;
  final TopicTree tree;

  @override
  State<TopicStatsView> createState() => _TopicStatsViewState();
}

class _TopicStatsViewState extends State<TopicStatsView> {
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = TopicStatistics.of(widget.node, DateTime.now());
    String rate(double v) =>
        v >= 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);
    String size(num bytes) => bytes >= 1 << 20
        ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB'
        : bytes >= 1024
        ? '${(bytes / 1024).toStringAsFixed(1)} KB'
        : l10n.mqttBytes(bytes.round());
    String age(Duration d) => d.inHours > 0
        ? l10n.mqttHoursAgo(d.inHours)
        : d.inMinutes > 0
        ? l10n.mqttMinutesAgo(d.inMinutes)
        : l10n.mqttSecondsAgo(d.inSeconds);

    final entries = <(String, String)>[
      (l10n.statsMessages, '${s.messageCount}'),
      if (s.firstSeen != null) (l10n.statsFirst, clockTime(s.firstSeen!)),
      if (s.lastSeen != null) (l10n.statsLast, clockTime(s.lastSeen!)),
      if (s.sinceLast != null) (l10n.statsSinceLast, age(s.sinceLast!)),
      if (s.overallRate != null)
        (l10n.statsRateOverall, l10n.statsRateValue(rate(s.overallRate!))),
      (
        l10n.statsRateRecent,
        s.recentRateIsLowerBound
            ? l10n.statsRateMinimum(rate(s.recentRate))
            : l10n.statsRateValue(rate(s.recentRate)),
      ),
      (l10n.statsAvgSize, size(s.averageSize)),
      (l10n.statsMinMaxSize, '${size(s.minSize)} / ${size(s.maxSize)}'),
      (l10n.statsHistory, '${s.historyLength}'),
      (
        l10n.statsHistoryMemory,
        l10n.statsHistoryMemoryValue(
          widget.tree.historyCount,
          size(widget.tree.historyBytes),
        ),
      ),
    ];
    return Column(
      key: const Key('topic.stats'),
      children: [
        for (final (label, value) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyMedium!.mono),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
