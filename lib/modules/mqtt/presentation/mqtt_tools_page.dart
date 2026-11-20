import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_controller.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/shared/interpretation/presentation/matrix_table.dart';

/// Broker info, topic tester and payload converter.
class MqttToolsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.toolsBrokerInfo),
              Tab(text: l10n.toolsTopicTester),
              Tab(text: l10n.toolsPayloadConverter),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                BrokerInfoView(),
                TopicTesterView(),
                PayloadConverterView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ broker info

class BrokerInfoView extends ConsumerWidget {
  const new({super.key});

  static String _label(AppLocalizations l10n, BrokerFigure f) => switch (f) {
    BrokerFigure.version => l10n.brokerVersion,
    BrokerFigure.uptime => l10n.brokerUptime,
    BrokerFigure.clientsConnected => l10n.brokerClientsConnected,
    BrokerFigure.clientsTotal => l10n.brokerClientsTotal,
    BrokerFigure.clientsMaximum => l10n.brokerClientsMaximum,
    BrokerFigure.subscriptions => l10n.brokerSubscriptions,
    BrokerFigure.retained => l10n.brokerRetained,
    BrokerFigure.messagesReceived => l10n.brokerMessagesReceived,
    BrokerFigure.messagesSent => l10n.brokerMessagesSent,
    BrokerFigure.loadReceived1m => l10n.brokerLoadReceived,
    BrokerFigure.loadSent1m => l10n.brokerLoadSent,
    BrokerFigure.bytesReceived => l10n.brokerBytesReceived,
    BrokerFigure.bytesSent => l10n.brokerBytesSent,
    BrokerFigure.heap => l10n.brokerHeap,
  };

  /// `1234 seconds` → `20 min 34 s`; other formats unchanged.
  static String formatUptime(String raw) {
    final seconds = int.tryParse(raw.split(' ').first);
    if (seconds == null) return raw;
    final d = seconds ~/ 86400;
    final h = seconds % 86400 ~/ 3600;
    final m = seconds % 3600 ~/ 60;
    final s = seconds % 60;
    return [
      if (d > 0) '$d d',
      if (d > 0 || h > 0) '$h h',
      if (d == 0 && (h > 0 || m > 0)) '$m min',
      if (d == 0 && h == 0) '$s s',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tree = ref.watch(mqttTopicTreeControllerProvider).tree;
    final info = BrokerInfo.fromTree(tree);
    final connected = ref.watch(
      mqttConnectionControllerProvider.select((s) => s.isConnected),
    );
    if (info.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.brokerInfoEmpty,
                key: const Key('broker.empty'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('broker.subscribe'),
                onPressed: connected
                    ? () => ref
                          .read(mqttConnectionControllerProvider.notifier)
                          .putSubscription(
                            const MqttSubscriptionSpec(filter: r'$SYS/#'),
                          )
                    : null,
                icon: const Icon(Icons.add_alert_outlined),
                label: Text(l10n.brokerInfoSubscribe),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      key: const Key('broker.info'),
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final figure in BrokerFigure.values)
              if (info.values[figure] case (final topic, final value))
                Tooltip(
                  message: topic,
                  child: SizedBox(
                    width: figure == BrokerFigure.version ? 360 : 200,
                    child: Card.outlined(
                      key: Key('broker.${figure.name}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(l10n, figure),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              figure == BrokerFigure.uptime
                                  ? formatUptime(value)
                                  : value,
                              style: theme.textTheme.titleMedium!.mono,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- topic tester

class TopicTesterView extends StatefulWidget {
  const new({super.key});

  @override
  State<TopicTesterView> createState() => _TopicTesterViewState();
}

class _TopicTesterViewState extends State<TopicTesterView> {
  final _filter = TextEditingController(text: 'home/+/temperature');
  final _topics = TextEditingController(
    text:
        'home/kitchen/temperature\nhome/kitchen/humidity\n'
        'home/temperature\n\$SYS/broker/uptime',
  );

  @override
  void dispose() {
    _filter.dispose();
    _topics.dispose();
    super.dispose();
  }

  String _explain(AppLocalizations l10n, MatchExplanation e) =>
      switch (e.reason) {
        MatchReason.match => l10n.testerMatch,
        MatchReason.matchMultiLevel => l10n.testerMatchMulti(e.level! + 1),
        MatchReason.levelMismatch => l10n.testerLevelMismatch(e.level! + 1),
        MatchReason.topicTooShort => l10n.testerTooShort(e.level! + 1),
        MatchReason.topicTooLong => l10n.testerTooLong,
        MatchReason.dollarTopic => l10n.testerDollar,
        MatchReason.invalidFilter => l10n.testerInvalidFilter(
          topicErrorText(l10n, e.filterError) ?? '',
        ),
        MatchReason.invalidTopic => l10n.testerInvalidTopic(
          topicErrorText(l10n, e.topicError) ?? '',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final colors = context.appColors;
    final filter = _filter.text.trim();
    final filterError = topicErrorText(l10n, validateTopicFilter(filter));
    final topics = _topics.text
        .split('\n')
        .map((t) => t.trimRight())
        .where((t) => t.isNotEmpty)
        .toList();

    return ListView(
      key: const Key('tester'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(l10n.testerHelp, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tester.filter'),
          controller: _filter,
          style: mono,
          decoration: InputDecoration(
            labelText: l10n.testerFilter,
            errorText: filterError,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tester.topics'),
          controller: _topics,
          style: mono,
          minLines: 3,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: l10n.testerTopics,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (filterError == null)
          for (final (i, topic) in topics.indexed)
            Builder(
              builder: (context) {
                final e = explainMatch(filter, topic);
                return ListTile(
                  key: Key('tester.result.$i'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.matches ? Icons.check_circle : Icons.cancel_outlined,
                    color: e.matches ? colors.success : theme.colorScheme.error,
                  ),
                  title: Text(topic, style: mono),
                  subtitle: Text(_explain(l10n, e)),
                );
              },
            ),
      ],
    );
  }
}

// -------------------------------------------------------- payload converter

class PayloadConverterView extends StatefulWidget {
  const new({super.key});

  @override
  State<PayloadConverterView> createState() => _PayloadConverterViewState();
}

class _PayloadConverterViewState extends State<PayloadConverterView> {
  final _input = TextEditingController(text: '41 48 00 00');
  PayloadFormat _format = PayloadFormat.hex;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    Uint8List? bytes;
    String? error;
    try {
      bytes = encodePayload(_input.text, _format);
    } on FormatException catch (e) {
      error = e.message;
    }
    String? utf;
    if (bytes != null) {
      try {
        utf = utf8.decode(bytes);
      } on FormatException {
        utf = null;
      }
    }
    void copy(String label, String text) {
      Clipboard.setData(ClipboardData(text: text)).ignore();
      ScaffoldMessenger.of(context).showReplacing(l10n.converterCopied(label));
    }

    final outputs = bytes == null
        ? const <(String, String)>[]
        : [
            (l10n.converterLength, l10n.mqttBytes(bytes.length)),
            ('Text (UTF-8)', utf ?? l10n.converterInvalidUtf8),
            ('Hex', formatHexBytes(bytes)),
            ('Base64', base64.encode(bytes)),
            (l10n.converterDecimal, bytes.join(' ')),
            (
              l10n.converterCArray,
              '{${bytes.map((b) => '0x${formatHexBytes([b])}').join(', ')}}',
            ),
          ];

    return ListView(
      key: const Key('converter'),
      padding: const EdgeInsets.all(12),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<PayloadFormat>(
            key: const Key('converter.format'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: PayloadFormat.text, label: Text('Text')),
              ButtonSegment(value: PayloadFormat.hex, label: Text('Hex')),
              ButtonSegment(value: PayloadFormat.base64, label: Text('Base64')),
              ButtonSegment(value: PayloadFormat.json, label: Text('JSON')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.single),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('converter.input'),
          controller: _input,
          style: mono,
          minLines: 2,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: l10n.converterInput,
            errorText: error == null ? null : l10n.converterInvalid(error),
            errorMaxLines: 2,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        for (final (label, value) in outputs)
          ListTile(
            key: Key('converter.out.$label'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: theme.textTheme.labelMedium),
            subtitle: SelectableText(value, style: mono),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: l10n.converterCopied(label),
              onPressed: () => copy(label, value),
            ),
          ),
        if (bytes != null && bytes.length >= 2) ...[
          const SizedBox(height: 12),
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: InterpretationMatrixTable(
              matrix: InterpretationMatrix.fromBytes(bytes),
              allowAddToMap: false,
              countInBytes: true,
              onCellAction: (row, cell, action) {
                final value = ValueFormatter.format(cell.value);
                copy(value, value);
              },
            ),
          ),
        ],
      ],
    );
  }
}
