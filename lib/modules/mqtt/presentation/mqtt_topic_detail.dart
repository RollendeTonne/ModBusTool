import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_history_settings.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_publish_draft.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/payload_view.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/topic_history_views.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

/// Selected topic: path, counters, actions, then tabs for the message
/// (all representations), its history, a comparison of two messages, a
/// chart of one value and statistics.
class MqttTopicDetail extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MqttTopicDetail> createState() => _MqttTopicDetailState();
}

enum _DetailTab { message, history, diff, chart, stats }

class _MqttTopicDetailState extends ConsumerState<MqttTopicDetail>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: _DetailTab.values.length,
    vsync: this,
  );

  /// Older message picked in the history; `null` = follow the latest.
  MqttMessageRecord? _viewed;
  String? _path;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showTab(_DetailTab tab) => _tabs.index = tab.index;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final path = ref.watch(
      topicTreeViewControllerProvider.select((v) => v.selected),
    );
    if (path != _path) {
      _path = path;
      _viewed = null;
    }
    // Rebuilds with every tree version, i.e. live while messages arrive.
    final snapshot = ref.watch(mqttTopicTreeControllerProvider);
    final node = path == null ? null : snapshot.tree.find(path);
    if (node == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.mqttDetailNone, textAlign: TextAlign.center),
        ),
      );
    }
    final last = node.last;
    // A picked message that fell out of the history shows the latest.
    final viewed =
        _viewed != null && node.history.any((r) => identical(r, _viewed))
        ? _viewed
        : null;
    final shown = viewed ?? last;
    final connected = ref.watch(
      mqttConnectionControllerProvider.select((s) => s.isConnected),
    );
    final perTopic = ref.watch(
      mqttHistorySettingsProvider.select((s) => s.perTopic),
    );
    final chartField =
        ref.watch(chartFieldsProvider.select((m) => m[node.path])) ??
        defaultChartField(last);
    final messenger = ScaffoldMessenger.of(context);
    Future<void> copy(String text) async {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showReplacing(l10n.mqttCopied);
    }

    void chartThis(ChartField field) {
      ref.read(chartFieldsProvider.notifier).set(node.path, field);
      _showTab(_DetailTab.chart);
    }

    final subtree = node.hasChildren ? '${node.path}/#' : node.path;
    final tab = _DetailTab.values[_tabs.index];

    return ListView(
      key: const Key('mqtt.detail'),
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectableText(
                node.path,
                key: const Key('mqtt.detail.topic'),
                style: mono.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: l10n.mqttCopyTopic,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => copy(node.path),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const Key('mqtt.detail.usePublish'),
              avatar: const Icon(Icons.send_outlined, size: 18),
              label: Text(l10n.mqttUseForPublish),
              onPressed: () => ref
                  .read(mqttPublishDraftProvider.notifier)
                  .useTopic(node.path),
            ),
            ActionChip(
              key: const Key('mqtt.detail.subscribe'),
              avatar: const Icon(Icons.add_alert_outlined, size: 18),
              label: Text(l10n.mqttSubscribeSubtree(subtree)),
              onPressed: connected
                  ? () => ref
                        .read(mqttConnectionControllerProvider.notifier)
                        .putSubscription(MqttSubscriptionSpec(filter: subtree))
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Facts(
          entries: [
            (l10n.mqttDetailMessages, '${node.messageCount}'),
            if (node.hasChildren)
              (l10n.mqttDetailSubtopics, '${node.descendantTopics}'),
            if (last != null) ...[
              (l10n.mqttDetailReceived, _Clock.format(last.timestamp)),
              (
                l10n.mqttDetailFlags,
                [
                  'QoS ${last.qos.value}',
                  if (last.retain) l10n.mqttRetainedBadge,
                  if (last.duplicate) 'DUP',
                ].join(' · '),
              ),
              (l10n.mqttDetailSize, l10n.mqttBytes(last.payload.length)),
              if (node.hasChanged && node.lastChangedAt != null)
                (l10n.mqttDetailChanged, _Clock.format(node.lastChangedAt!)),
            ],
          ],
        ),
        if (last != null) ...[
          _Ago(time: last.timestamp),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final t in _DetailTab.values)
                Tab(
                  key: Key('topic.tab.${t.name}'),
                  text: switch (t) {
                    _DetailTab.message => l10n.topicTabMessage,
                    _DetailTab.history => l10n.topicTabHistory,
                    _DetailTab.diff => l10n.topicTabDiff,
                    _DetailTab.chart => l10n.topicTabChart,
                    _DetailTab.stats => l10n.topicTabStats,
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          switch (tab) {
            _DetailTab.message => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: viewed == null
                          ? Text(
                              l10n.mqttDetailLast,
                              style: theme.textTheme.titleSmall,
                            )
                          : Text(
                              l10n.historyViewing(
                                _Clock.format(viewed.timestamp),
                              ),
                              key: const Key('topic.viewingOlder'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                    ),
                    if (viewed != null)
                      TextButton(
                        key: const Key('topic.showLatest'),
                        onPressed: () => setState(() => _viewed = null),
                        child: Text(l10n.historyShowLatest),
                      ),
                    IconButton(
                      key: const Key('mqtt.detail.copyPayload'),
                      tooltip: l10n.mqttCopyPayload,
                      icon: const Icon(Icons.copy_all, size: 18),
                      onPressed: () => copy(_payloadText(shown!.payload)),
                    ),
                  ],
                ),
                PayloadView(
                  record: shown!,
                  topic: node.path,
                  onChartField: chartThis,
                ),
              ],
            ),
            _DetailTab.history => TopicHistoryList(
              node: node,
              perTopicLimit: perTopic,
              viewed: viewed,
              onView: (record) => setState(() {
                _viewed = identical(record, last) ? null : record;
                _showTab(_DetailTab.message);
              }),
            ),
            _DetailTab.diff => TopicDiffView(node: node),
            _DetailTab.chart => TopicChartView(
              node: node,
              field: chartField,
              onClear: () =>
                  ref.read(chartFieldsProvider.notifier).set(node.path, null),
            ),
            _DetailTab.stats => TopicStatsView(node: node, tree: snapshot.tree),
          },
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(l10n.mqttDetailBranch),
          ),
      ],
    );
  }

  /// UTF-8 text if valid and printable, otherwise a hex listing.
  static String _payloadText(Uint8List payload) {
    try {
      final text = utf8.decode(payload);
      if (!RegExp('[\u0000-\u0008\u000E-\u001F]').hasMatch(text)) return text;
    } on FormatException {
      // binary
    }
    return formatHexBytes(payload);
  }
}

class _Facts extends StatelessWidget {
  const new({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
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

abstract final class _Clock {
  static String format(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }
}

/// "5 s ago", refreshed every second.
class _Ago extends StatefulWidget {
  const new({required this.time});

  final DateTime time;

  @override
  State<_Ago> createState() => _AgoState();
}

class _AgoState extends State<_Ago> {
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
    final age = DateTime.now().difference(widget.time);
    final text = age.inHours > 0
        ? l10n.mqttHoursAgo(age.inHours)
        : age.inMinutes > 0
        ? l10n.mqttMinutesAgo(age.inMinutes)
        : l10n.mqttSecondsAgo(age.inSeconds.clamp(0, 59));
    return Padding(
      padding: const EdgeInsets.only(left: 140, top: 2),
      child: Text(
        text,
        key: const Key('mqtt.detail.ago'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
