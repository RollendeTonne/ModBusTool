import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_history_settings.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_message_log_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_replay_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_replay_dialog.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topics_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/payload_view.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/topic_history_views.dart';

const jsonLinesFileType = ExchangeFileType(
  label: 'JSON Lines',
  extension: 'jsonl',
  mimeType: 'application/x-ndjson',
  uti: 'public.plain-text',
);

/// Chronological log of messages and connection events with filters,
/// export, replay and an adjustable ring buffer.
class MqttMonitorPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MqttMonitorPage> createState() => _MqttMonitorPageState();
}

class _MqttMonitorPageState extends ConsumerState<MqttMonitorPage> {
  final _topic = TextEditingController();
  final _payload = TextEditingController();
  final _topicFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(monitorFilterProvider);
    _topic.text = filter.topic;
    _payload.text = filter.payload;
  }

  @override
  void dispose() {
    _topic.dispose();
    _payload.dispose();
    _topicFocus.dispose();
    super.dispose();
  }

  void _update(MonitorFilter Function(MonitorFilter f) change) =>
      ref.read(monitorFilterProvider.notifier).update(change);

  Future<void> _export(String format) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(filteredLogProvider);
    if (entries.isEmpty) {
      messenger.showReplacing(l10n.monitorExportEmpty);
      return;
    }
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final (content, type) = switch (format) {
      'csv' => (exportCsv(entries), ExchangeFileType.csv),
      'jsonl' => (exportJsonLines(entries), jsonLinesFileType),
      _ => (exportText(entries), ExchangeFileType.text),
    };
    final name = 'mqtt-log-$stamp.${type.extension}';
    try {
      final saved = await ref
          .read(fileExchangeProvider)
          .saveText(suggestedName: name, content: content, type: type);
      if (saved) messenger.showReplacing(l10n.exportSaved(name));
    } on Object catch (e) {
      messenger.showReplacing(l10n.exportFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final log = ref.watch(mqttMessageLogControllerProvider);
    final filter = ref.watch(monitorFilterProvider);
    final entries = ref.watch(filteredLogProvider);
    final replay = ref.watch(mqttReplayControllerProvider);
    final controller = ref.read(mqttMessageLogControllerProvider.notifier);
    final mono = theme.textTheme.bodyMedium!.mono;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    void focusFilter() => _topicFocus.requestFocus();

    Widget chip(String key, String label, bool value, ValueChanged<bool> set) =>
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            key: Key('mqtt.monitor.$key'),
            label: Text(label),
            selected: value,
            onSelected: set,
          ),
        );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            controller.clear,
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true):
            controller.clear,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            focusFilter,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): focusFilter,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const MqttNotConnectedBanner(),
            if (replay.running)
              MaterialBanner(
                key: const Key('mqtt.replay.banner'),
                leading: const Icon(Icons.replay),
                content: Text(l10n.replayRunning(replay.done, replay.total)),
                actions: [
                  TextButton(
                    key: const Key('mqtt.replay.stop'),
                    onPressed: () =>
                        ref.read(mqttReplayControllerProvider.notifier).stop(),
                    child: Text(l10n.replayStop),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      key: const Key('mqtt.monitor.topic'),
                      controller: _topic,
                      focusNode: _topicFocus,
                      style: mono,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.monitorTopicFilter,
                        hintText: 'a/+/b, #',
                        errorText: filter.topicError == null
                            ? null
                            : l10n.mqttTreeFilterError(filter.topicError!),
                        errorMaxLines: 2,
                      ),
                      onChanged: (t) => _update((f) => f.copyWith(topic: t)),
                    ),
                  ),
                  DropdownButton<TopicFilterMode>(
                    key: const Key('mqtt.monitor.mode'),
                    value: filter.mode,
                    items: [
                      DropdownMenuItem(
                        value: TopicFilterMode.wildcard,
                        child: Text(l10n.mqttFilterWildcard),
                      ),
                      DropdownMenuItem(
                        value: TopicFilterMode.text,
                        child: Text(l10n.mqttFilterText),
                      ),
                      DropdownMenuItem(
                        value: TopicFilterMode.regex,
                        child: Text(l10n.mqttFilterRegex),
                      ),
                    ],
                    onChanged: (m) => _update((f) => f.copyWith(mode: m)),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      key: const Key('mqtt.monitor.payload'),
                      controller: _payload,
                      style: mono,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.monitorPayloadFilter,
                        hintText: l10n.monitorPayloadFilterHint,
                      ),
                      onChanged: (t) => _update((f) => f.copyWith(payload: t)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          chip(
                            'rx',
                            l10n.monitorRx,
                            filter.showReceived,
                            (v) => _update((f) => f.copyWith(showReceived: v)),
                          ),
                          chip(
                            'tx',
                            l10n.monitorTx,
                            filter.showSent,
                            (v) => _update((f) => f.copyWith(showSent: v)),
                          ),
                          chip(
                            'events',
                            l10n.monitorEvents,
                            filter.showEvents,
                            (v) => _update((f) => f.copyWith(showEvents: v)),
                          ),
                          chip(
                            'retained',
                            l10n.monitorOnlyRetained,
                            filter.onlyRetained,
                            (v) => _update((f) => f.copyWith(onlyRetained: v)),
                          ),
                          chip(
                            'errors',
                            l10n.monitorOnlyErrors,
                            filter.onlyErrors,
                            (v) => _update((f) => f.copyWith(onlyErrors: v)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('mqtt.pause'),
                    tooltip: log.paused ? l10n.mqttResume : l10n.mqttPause,
                    icon: Icon(log.paused ? Icons.play_arrow : Icons.pause),
                    onPressed: () => controller.setPaused(paused: !log.paused),
                  ),
                  IconButton(
                    key: const Key('mqtt.clear'),
                    tooltip: '${l10n.mqttClear} (${mac ? '⌘L' : 'Ctrl+L'})',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: controller.clear,
                  ),
                  PopupMenuButton<String>(
                    key: const Key('mqtt.monitor.export'),
                    tooltip: l10n.monitorExport,
                    icon: const Icon(Icons.file_download_outlined),
                    onSelected: _export,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'text',
                        child: Text(l10n.monitorExportText),
                      ),
                      PopupMenuItem(
                        value: 'csv',
                        child: Text(l10n.monitorExportCsv),
                      ),
                      PopupMenuItem(
                        value: 'jsonl',
                        child: Text(l10n.monitorExportJsonl),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const Key('mqtt.monitor.replay'),
                    tooltip: l10n.replayTitle,
                    icon: const Icon(Icons.replay),
                    onPressed: () => showReplayDialog(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mqttMonitorCount(
                        entries.length,
                        log.total,
                        log.capacity,
                      ),
                      key: const Key('mqtt.messageCount'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    l10n.monitorBufferSize,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    key: const Key('mqtt.monitor.size'),
                    isDense: true,
                    value: log.capacity,
                    items: [
                      for (final n in MqttHistorySettings.monitorChoices)
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (n) => ref
                        .read(mqttHistorySettingsProvider.notifier)
                        .setMonitorSize(n!),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        log.entries.isEmpty
                            ? l10n.mqttMonitorEmpty
                            : l10n.monitorNoMatch,
                      ),
                    )
                  : ListView.builder(
                      key: const Key('mqtt.messageList'),
                      itemCount: entries.length,
                      itemExtent: 56,
                      itemBuilder: (context, i) {
                        final entry = entries[entries.length - 1 - i];
                        return switch (entry) {
                          MqttLogMessage(:final record) => _MessageRow(
                            key: Key('mqtt.monitor.row.$i'),
                            record: record,
                          ),
                          MqttLogEvent() => _EventRow(
                            key: Key('mqtt.monitor.row.$i'),
                            event: entry,
                          ),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String eventText(AppLocalizations l10n, MqttLogEvent e) => switch (e.kind) {
  MqttEventKind.connecting => l10n.eventConnecting(e.detail),
  MqttEventKind.connected => l10n.eventConnected(e.detail),
  MqttEventKind.connectFailed => l10n.eventConnectFailed(e.detail),
  MqttEventKind.subscribe => l10n.eventSubscribe(e.detail),
  MqttEventKind.unsubscribe => l10n.eventUnsubscribe(e.detail),
  MqttEventKind.disconnect => l10n.eventDisconnect,
  MqttEventKind.connectionLost => l10n.eventConnectionLost(e.detail),
  MqttEventKind.reconnectScheduled => l10n.eventReconnect(e.detail),
  MqttEventKind.publishFailed => l10n.eventPublishFailed(e.detail),
  MqttEventKind.replayStarted => l10n.eventReplayStarted(e.detail),
  MqttEventKind.replayFinished => l10n.eventReplayFinished(e.detail),
};

class _EventRow extends StatelessWidget {
  const new({required this.event, super.key});

  final MqttLogEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = event.kind.isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            event.kind.isError ? Icons.error_outline : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            clockTime(event.timestamp),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${event.kind.keyword} · ${eventText(l10n, event)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const new({required this.record, super.key});

  final MqttMessageRecord record;

  void _open(BuildContext context) {
    final l10n = context.l10n;
    final sent = record.direction == MqttDirection.sent;
    showModalBottomSheet<void>(
      context: context,
      // Above the navigation bar, like the full-screen editors.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          key: const Key('mqtt.monitor.sheet'),
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l10n.monitorMessageTitle(
                sent ? l10n.mqttTx : l10n.mqttRx,
                record.topic,
              ),
              style: Theme.of(context).textTheme.titleMedium!.mono,
            ),
            const SizedBox(height: 8),
            PayloadView(record: record, topic: record.topic),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall!.mono;
    final sent = record.direction == MqttDirection.sent;
    final flags = [
      'QoS ${record.qos.value}',
      if (record.retain) 'R',
      if (record.duplicate) 'DUP',
      '${record.payload.length} B',
    ].join(' · ');

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Tooltip(
              message: sent ? l10n.mqttTx : l10n.mqttRx,
              child: Icon(
                sent ? Icons.north_east : Icons.south_west,
                size: 18,
                color: sent
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          record.topic,
                          style: mono.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${clockTime(record.timestamp)} · $flags',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    payloadPreview(record.payload),
                    style: mono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
