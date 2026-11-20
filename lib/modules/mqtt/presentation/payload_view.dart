import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/shared/interpretation/presentation/matrix_table.dart';

enum PayloadTab { content, text, hex, binary, meta }

/// A message shown in several representations at once: detected type,
/// content (JSON tree / XML / text / Base64), text with encoding, hex dump,
/// binary interpretation via the shared engine, MQTT metadata.
///
/// Embedded in a scrolling parent, so tab contents size themselves (no
/// TabBarView) and very large payloads are cut off with "show more".
class PayloadView extends StatefulWidget {
  const new({
    required this.record,
    required this.topic,
    this.onChartField,
    super.key,
  });

  final MqttMessageRecord record;

  /// "Show in chart" from the JSON tree or the binary view.
  final ValueChanged<ChartField>? onChartField;

  /// Changing the topic resets the tab to the best one for its content.
  final String topic;

  /// Longest text rendered inline (characters).
  static const int maxTextChars = 64 * 1024;

  @override
  State<PayloadView> createState() => _PayloadViewState();
}

class _PayloadViewState extends State<PayloadView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: PayloadTab.values.length,
    vsync: this,
    initialIndex: _defaultTab().index,
  );

  TextEncoding _encoding = TextEncoding.utf8;
  int _offset = 0;
  bool _decodedSource = false;
  int _hexLines = 256;
  DataType _chartType = DataType.float32;
  ByteOrderFamily _chartOrder = ByteOrderFamily.abcd;

  PayloadAnalysis get _analysis => analyzeCached(
    widget.record.payload,
    contentType: widget.record.properties.contentType,
  );

  PayloadTab _defaultTab() => switch (_analysis.kind) {
    PayloadKind.binary => PayloadTab.binary,
    PayloadKind.empty => PayloadTab.meta,
    _ => PayloadTab.content,
  };

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(PayloadView old) {
    super.didUpdateWidget(old);
    if (old.topic != widget.topic) {
      _offset = 0;
      _decodedSource = false;
      _hexLines = 256;
      _tabs.index = _defaultTab().index;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _copy(String text, String message) {
    unawaitedCopy(text);
    ScaffoldMessenger.of(context).showReplacing(message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final analysis = _analysis;
    final kind = switch (analysis.kind) {
      PayloadKind.empty => l10n.payloadKindEmpty,
      PayloadKind.json when analysis.syntaxIssue != null =>
        l10n.payloadKindJsonBroken,
      PayloadKind.json => l10n.payloadKindJson,
      PayloadKind.xml when analysis.syntaxIssue != null =>
        l10n.payloadKindXmlBroken,
      PayloadKind.xml => l10n.payloadKindXml,
      PayloadKind.text => l10n.payloadKindText,
      PayloadKind.base64 => l10n.payloadKindBase64,
      PayloadKind.binary => l10n.payloadKindBinary,
    };
    final tab = PayloadTab.values[_tabs.index];

    return Column(
      key: const Key('payload.view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          key: const Key('payload.kind'),
          avatar: Icon(switch (analysis.kind) {
            PayloadKind.json => Icons.data_object,
            PayloadKind.xml => Icons.code,
            PayloadKind.binary => Icons.memory,
            PayloadKind.base64 => Icons.lock_open_outlined,
            _ => Icons.notes,
          }, size: 18),
          label: Text(l10n.payloadDetected(kind)),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final t in PayloadTab.values)
              Tab(
                key: Key('payload.tab.${t.name}'),
                text: switch (t) {
                  PayloadTab.content => l10n.payloadTabContent,
                  PayloadTab.text => l10n.payloadTabText,
                  PayloadTab.hex => l10n.payloadTabHex,
                  PayloadTab.binary => l10n.payloadTabBinary,
                  PayloadTab.meta => l10n.payloadTabMeta,
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (tab) {
          PayloadTab.content => _content(context, analysis),
          PayloadTab.text => _text(context),
          PayloadTab.hex => _hex(context, widget.record.payload),
          PayloadTab.binary => _binary(context, analysis),
          PayloadTab.meta => _meta(context),
        },
      ],
    );
  }

  // ------------------------------------------------------------ content

  Widget _content(BuildContext context, PayloadAnalysis a) {
    final l10n = context.l10n;
    switch (a.kind) {
      case PayloadKind.empty:
        return Text(l10n.payloadEmpty);
      case PayloadKind.binary:
        return Text(l10n.payloadBinaryHint);
      case PayloadKind.json:
        return _JsonContent(
          analysis: a,
          onCopyPath: (path) => _copy(path, l10n.payloadPathCopied(path)),
          onChart: widget.onChartField == null
              ? null
              : (path) => widget.onChartField!(JsonPathField(path)),
        );
      case PayloadKind.xml:
        return _XmlContent(analysis: a);
      case PayloadKind.text:
        return _MonoBox(text: _cap(a.text!), key: const Key('payload.text'));
      case PayloadKind.base64:
        final decoded = a.base64Decoded!;
        final inner = analyzePayload(decoded);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.payloadBase64Decoded(decoded.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (inner.kind == PayloadKind.text ||
                inner.kind == PayloadKind.json)
              _MonoBox(
                text: _cap(inner.text!),
                key: const Key('payload.base64'),
              )
            else
              _MonoBox(
                key: const Key('payload.base64'),
                text: hexDump(decoded, maxLines: 32)
                    .map((l) => '${l.offsetLabel}  ${l.hex}  ${l.ascii}')
                    .join('\n'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('payload.interpretDecoded'),
              onPressed: () => setState(() {
                _decodedSource = true;
                _offset = 0;
                _tabs.index = PayloadTab.binary.index;
              }),
              icon: const Icon(Icons.calculate_outlined),
              label: Text(l10n.payloadInterpretDecoded),
            ),
          ],
        );
    }
  }

  String _cap(String text) => text.length > PayloadView.maxTextChars
      ? '${text.substring(0, PayloadView.maxTextChars)}…'
      : text;

  // --------------------------------------------------------------- text

  Widget _text(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.payloadEncoding),
            _Segments(
              child: SegmentedButton<TextEncoding>(
                key: const Key('payload.encoding'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: TextEncoding.utf8, label: Text('UTF-8')),
                  ButtonSegment(
                    value: TextEncoding.ascii,
                    label: Text('ASCII'),
                  ),
                  ButtonSegment(
                    value: TextEncoding.latin1,
                    label: Text('Latin-1'),
                  ),
                ],
                selected: {_encoding},
                onSelectionChanged: (s) => setState(() => _encoding = s.single),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MonoBox(
          key: const Key('payload.decodedText'),
          text: _cap(decodeText(widget.record.payload, _encoding)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- hex

  Widget _hex(BuildContext context, Uint8List bytes) {
    final l10n = context.l10n;
    final total = (bytes.length / 16).ceil();
    final lines = hexDump(bytes, maxLines: _hexLines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _MonoBox(
            key: const Key('payload.hex'),
            expand: false,
            text: lines
                .map((l) => '${l.offsetLabel}  ${l.hex}  │${l.ascii}')
                .join('\n'),
          ),
        ),
        if (lines.length < total) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.payloadHexLines(lines.length, total)),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _hexLines += 1024),
                child: Text(l10n.payloadShowMore),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------- binary

  Widget _binary(BuildContext context, PayloadAnalysis a) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final decoded = a.base64Decoded;
    final source = _decodedSource && decoded != null
        ? decoded
        : widget.record.payload;
    final maxOffset = source.isEmpty ? 0 : source.length - 1;
    final offset = _offset.clamp(0, maxOffset);
    final window = byteWindow(source, offset);
    final eight = byteValues(source, offset);

    void setOffset(int value) =>
        setState(() => _offset = value.clamp(0, maxOffset));

    return Column(
      key: const Key('payload.binary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decoded != null) ...[
          _Segments(
            child: SegmentedButton<bool>(
              key: const Key('payload.source'),
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.payloadSourcePayload),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.payloadSourceBase64),
                ),
              ],
              selected: {_decodedSource},
              onSelectionChanged: (s) => setState(() {
                _decodedSource = s.single;
                _offset = 0;
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            IconButton(
              key: const Key('payload.offset.down'),
              icon: const Icon(Icons.remove),
              onPressed: offset > 0 ? () => setOffset(offset - 1) : null,
            ),
            SizedBox(
              width: 140,
              child: _OffsetField(
                value: offset,
                max: maxOffset,
                onChanged: setOffset,
              ),
            ),
            IconButton(
              key: const Key('payload.offset.up'),
              icon: const Icon(Icons.add),
              onPressed: offset < maxOffset
                  ? () => setOffset(offset + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.payloadWindow(
            window.isEmpty
                ? '–'
                : '${formatHexBytes(window.take(8).toList())}'
                      '${window.length > 8 ? ' …' : ''}',
          ),
          key: const Key('payload.window'),
          style: mono,
        ),
        const SizedBox(height: 12),
        if (window.isEmpty)
          Text(l10n.payloadNoBytes)
        else ...[
          if (eight != null)
            Wrap(
              spacing: 16,
              children: [
                Text(l10n.payloadEightBit, style: theme.textTheme.labelLarge),
                Text(
                  'INT8 ${eight.$1}',
                  key: const Key('payload.int8'),
                  style: mono,
                ),
                Text(
                  'UINT8 ${eight.$2}',
                  key: const Key('payload.uint8'),
                  style: mono,
                ),
              ],
            ),
          const SizedBox(height: 8),
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: InterpretationMatrixTable(
              matrix: InterpretationMatrix.fromBytes(window),
              allowAddToMap: false,
              countInBytes: true,
              onCellAction: (row, cell, action) {
                final value = ValueFormatter.format(cell.value);
                _copy(value, l10n.payloadValueCopied(value));
              },
            ),
          ),
          if (widget.onChartField != null && !_decodedSource) ...[
            const SizedBox(height: 12),
            Text(
              l10n.chartBinaryHint(offset),
              style: theme.textTheme.bodySmall,
            ),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<DataType>(
                  key: const Key('payload.chartType'),
                  value: _chartType,
                  items: [
                    for (final t in InterpretationMatrix.defaultTypes)
                      if (t != DataType.unixTime32 &&
                          t != DataType.unixTime64Ms)
                        DropdownMenuItem(
                          value: t,
                          child: Text(t.technicalName),
                        ),
                  ],
                  onChanged: (t) => setState(() => _chartType = t!),
                ),
                DropdownButton<ByteOrderFamily>(
                  key: const Key('payload.chartOrder'),
                  value: _chartOrder,
                  items: [
                    for (final f in ByteOrderFamily.values)
                      DropdownMenuItem(
                        value: f,
                        child: Text(f.name.toUpperCase()),
                      ),
                  ],
                  onChanged: (f) => setState(() => _chartOrder = f!),
                ),
                FilledButton.tonalIcon(
                  key: const Key('payload.chartBinary'),
                  onPressed: () => widget.onChartField!(
                    BinaryField(
                      offset: offset,
                      type: _chartType,
                      order: _chartOrder,
                    ),
                  ),
                  icon: const Icon(Icons.show_chart),
                  label: Text(l10n.chartShowBinary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(l10n.payloadBits, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          _MonoBox(
            key: const Key('payload.bits'),
            text: [
              '            7654 3210',
              for (final (i, bits) in bitsOf(source, offset, 4).indexed)
                _bitLine(i, source[offset + i], bits),
            ].join('\n'),
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------------------- meta

  Widget _meta(BuildContext context) {
    final l10n = context.l10n;
    final r = widget.record;
    final p = r.properties;
    final entries = <(String, String)>[
      ('QoS', '${r.qos.value}'),
      (l10n.mqttRetain, r.retain ? '✓' : '–'),
      ('DUP', r.duplicate ? '✓' : '–'),
      (l10n.mqttDetailSize, l10n.mqttBytes(r.payload.length)),
      (l10n.mqttDetailReceived, r.timestamp.toIso8601String()),
      if (p.contentType != null) (l10n.payloadMetaContentType, p.contentType!),
      if (p.payloadIsUtf8 ?? false)
        (l10n.payloadMetaFormat, l10n.payloadMetaFormatUtf8),
      if (p.messageExpiry case final expiry?)
        (l10n.payloadMetaExpiry, l10n.payloadMetaSeconds(expiry.inSeconds)),
      if (p.topicAlias != null) (l10n.payloadMetaAlias, '${p.topicAlias}'),
      if (p.responseTopic != null) (l10n.payloadMetaResponse, p.responseTopic!),
      if (p.correlationData case final data?)
        (l10n.payloadMetaCorrelation, _textOrHex(data)),
      if (p.subscriptionIds.isNotEmpty)
        (l10n.payloadMetaSubIds, p.subscriptionIds.join(', ')),
    ];
    final theme = Theme.of(context);
    return Column(
      key: const Key('payload.meta'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in entries)
          _FactRow(label: label, value: value),
        if (p.userProperties.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.payloadMetaUserProps, style: theme.textTheme.titleSmall),
          for (final (name, value) in p.userProperties)
            _FactRow(label: name, value: value),
        ],
        if (p.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.payloadMetaNoV5, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }

  static String _bitLine(int index, int byte, List<int> bits) {
    final hex = formatHexBytes([byte]);
    final nibbles = '${bits.take(4).join()} ${bits.skip(4).join()}';
    return '+${index.toString().padRight(2)} 0x$hex   $nibbles';
  }

  static String _textOrHex(Uint8List data) {
    final a = analyzePayload(data);
    return a.kind == PayloadKind.binary ? formatHexBytes(data) : a.text ?? '';
  }
}

/// Fire-and-forget clipboard write (the snackbar confirms immediately).
void unawaitedCopy(String text) =>
    Clipboard.setData(ClipboardData(text: text)).ignore();

class _OffsetField extends StatefulWidget {
  const new({required this.value, required this.max, required this.onChanged});

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_OffsetField> createState() => _OffsetFieldState();
}

class _OffsetFieldState extends State<_OffsetField> {
  late final _controller = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(_OffsetField old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: const Key('payload.offset'),
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.bodyMedium!.mono,
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.payloadOffset,
        helperText: l10n.payloadOffsetHint(widget.max),
      ),
      onChanged: (text) {
        final value = int.tryParse(text);
        if (value != null) widget.onChanged(value);
      },
    );
  }
}

// ---------------------------------------------------------------- JSON

enum _JsonMode { tree, pretty, raw }

class _JsonContent extends StatefulWidget {
  const new({required this.analysis, required this.onCopyPath, this.onChart});

  final PayloadAnalysis analysis;
  final ValueChanged<String> onCopyPath;
  final ValueChanged<List<Object>>? onChart;

  @override
  State<_JsonContent> createState() => _JsonContentState();
}

class _JsonContentState extends State<_JsonContent> {
  _JsonMode _mode = _JsonMode.tree;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = widget.analysis;
    final issue = a.syntaxIssue;
    if (issue != null) {
      return _SyntaxError(text: a.text!, issue: issue);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Segments(
          child: SegmentedButton<_JsonMode>(
            key: const Key('payload.jsonMode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _JsonMode.tree,
                label: Text(l10n.payloadJsonTree),
              ),
              ButtonSegment(
                value: _JsonMode.pretty,
                label: Text(l10n.payloadJsonPretty),
              ),
              ButtonSegment(
                value: _JsonMode.raw,
                label: Text(l10n.payloadJsonRaw),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.single),
          ),
        ),
        const SizedBox(height: 8),
        switch (_mode) {
          _JsonMode.tree => JsonTreeView(
            json: a.json,
            onCopyPath: widget.onCopyPath,
            onChart: widget.onChart,
          ),
          _JsonMode.pretty => _MonoBox(
            key: const Key('payload.jsonPretty'),
            text: const JsonEncoder.withIndent('  ').convert(a.json),
          ),
          _JsonMode.raw => _MonoBox(text: a.text!),
        },
      ],
    );
  }
}

/// Collapsible JSON tree; a tap on a line copies its JSON path. Containers
/// up to depth 1 start open; long arrays/objects show the first
/// [maxChildren] entries.
class JsonTreeView extends StatefulWidget {
  const new({
    required this.json,
    required this.onCopyPath,
    this.onChart,
    super.key,
  });

  final Object? json;
  final ValueChanged<String> onCopyPath;

  /// Offered on numbers and booleans: chart this value over the history.
  final ValueChanged<List<Object>>? onChart;

  static const maxChildren = 200;
  static const maxRows = 2000;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  /// Toggled container paths (relative to the default expansion).
  final _toggled = <String>{};

  bool _isOpen(String path, int depth) =>
      (depth <= 1) != _toggled.contains(path);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = theme.textTheme.bodyMedium!.mono;
    final rows = <Widget>[];

    void add(Object? label, Object? value, List<Object> path, int depth) {
      if (rows.length >= JsonTreeView.maxRows) return;
      final pathText = jsonPath(path);
      final container = value is Map || value is List;
      final open = container && _isOpen(pathText, depth);
      final count = value is Map
          ? value.length
          : value is List
          ? value.length
          : 0;
      final (valueText, color) = switch (value) {
        Map() => ('{$count}', scheme.onSurfaceVariant),
        List() => ('[$count]', scheme.onSurfaceVariant),
        String() => ('"$value"', scheme.tertiary),
        num() => ('$value', scheme.primary),
        bool() || null => ('$value', scheme.secondary),
        _ => ('$value', null),
      };
      rows.add(
        InkWell(
          key: Key('json.$pathText'),
          onTap: () => widget.onCopyPath(pathText),
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: Row(
              children: [
                if (container)
                  InkWell(
                    key: Key('json.toggle.$pathText'),
                    onTap: () => setState(() {
                      if (!_toggled.remove(pathText)) _toggled.add(pathText);
                    }),
                    child: Icon(
                      open ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                if (label != null)
                  Text(
                    label is int ? '[$label] ' : '$label: ',
                    style: mono.copyWith(fontWeight: FontWeight.w600),
                  ),
                Expanded(
                  child: Text(
                    valueText,
                    style: mono.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onChart != null && (value is num || value is bool))
                  IconButton(
                    key: Key('json.chart.$pathText'),
                    // Same height as the other rows (seen on a device).
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 24,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    tooltip: l10n.chartShowJson,
                    icon: const Icon(Icons.show_chart),
                    onPressed: () => widget.onChart!(path),
                  ),
              ],
            ),
          ),
        ),
      );
      if (!open) return;
      final entries = value is Map
          ? value.entries.map((e) => (e.key as Object, e.value))
          : (value! as List).indexed.map((e) => (e.$1 as Object, e.$2));
      var shown = 0;
      for (final (key, child) in entries) {
        if (shown++ >= JsonTreeView.maxChildren) {
          rows.add(
            Padding(
              padding: EdgeInsets.only(left: (depth + 1) * 16.0 + 24),
              child: Text(
                l10n.payloadMoreItems(count - JsonTreeView.maxChildren),
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
          break;
        }
        add(key, child, [...path, key], depth + 1);
      }
    }

    add(null, widget.json, const [], 0);
    return Column(
      key: const Key('payload.jsonTree'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.payloadCopyPathHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }
}

class _SyntaxError extends StatelessWidget {
  const new({required this.text, required this.issue});

  final String text;
  final SyntaxIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = issue.lineOf(text);
    return Column(
      key: const Key('payload.syntaxError'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payloadSyntaxError(
                  issue.line,
                  issue.column,
                  issue.message,
                ),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 8),
              // The broken line with a caret under the error position.
              Text(
                '$line\n${' ' * (issue.column - 1)}^',
                key: const Key('payload.syntaxCaret'),
                style: theme.textTheme.bodyMedium!.mono.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _MonoBox(text: text),
      ],
    );
  }
}

// ----------------------------------------------------------------- XML

class _XmlContent extends StatefulWidget {
  const new({required this.analysis});

  final PayloadAnalysis analysis;

  @override
  State<_XmlContent> createState() => _XmlContentState();
}

class _XmlContentState extends State<_XmlContent> {
  bool _pretty = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = widget.analysis;
    if (a.syntaxIssue != null) {
      return _SyntaxError(text: a.text!, issue: a.syntaxIssue!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Segments(
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(l10n.payloadJsonPretty)),
              ButtonSegment(value: false, label: Text(l10n.payloadJsonRaw)),
            ],
            selected: {_pretty},
            onSelectionChanged: (s) => setState(() => _pretty = s.single),
          ),
        ),
        const SizedBox(height: 8),
        _MonoBox(
          key: const Key('payload.xml'),
          text: _pretty ? prettyXml(a.text!) : a.text!,
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- shared

class _MonoBox extends StatelessWidget {
  const new({required this.text, this.expand = true, super.key});

  final String text;

  /// Full width; off inside horizontal scroll views (unbounded width).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(text, style: theme.textTheme.bodyMedium!.mono),
    );
  }
}

class _FactRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium!.mono,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segment buttons scroll sideways instead of overflowing narrow columns.
class _Segments extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
}
