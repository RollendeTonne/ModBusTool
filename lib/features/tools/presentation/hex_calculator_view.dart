import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/text_decoder.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_decoder.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_encoder.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/interpretation/presentation/map_entry_dialog.dart';
import 'package:modbus_explorer/features/interpretation/presentation/matrix_table.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';
import 'package:modbus_explorer/features/tools/domain/hex_input.dart';

/// Converts arbitrary bytes/registers into every format and back, without
/// a connection.
class HexCalculatorView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HexCalculatorView> createState() => _HexCalculatorViewState();
}

class _HexCalculatorViewState extends ConsumerState<HexCalculatorView> {
  final _input = TextEditingController(text: '41 20 00 00');
  final _pattern = TextEditingController(text: 'EFGHABCD');
  final _encodeValue = TextEditingController(text: '230.1');
  HexInputMode _mode = HexInputMode.bytes;
  DataType _patternType = DataType.float64;
  DataType _encodeType = DataType.float32;
  String _encodeOrder = 'ABCD';

  @override
  void dispose() {
    _input.dispose();
    _pattern.dispose();
    _encodeValue.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showReplacing(context.l10n.copiedValue(text));
    }
  }

  void _useAsInput(List<int> registers) => setState(() {
    _mode = HexInputMode.registersHex;
    _input.text = registers.map((r) => formatHex(r, prefix: false)).join(' ');
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final highlight = ref.watch(
      settingsControllerProvider.select((s) => s.highlightPlausible),
    );
    final result = parseHexInput(_input.text, _mode);
    final registers = result.registers;

    return ListView(
      key: const Key('hex.view'),
      padding: const EdgeInsets.all(12),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<HexInputMode>(
            key: const Key('hex.mode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: HexInputMode.bytes,
                label: Text(l10n.hexModeBytes),
              ),
              ButtonSegment(
                value: HexInputMode.registersHex,
                label: Text(l10n.hexModeRegisters),
              ),
              ButtonSegment(
                value: HexInputMode.registersDecimal,
                label: Text(l10n.hexModeDecimal),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.single),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('hex.input'),
          controller: _input,
          style: mono,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.hexInput,
            hintText: l10n.hexInputHint,
            errorText: result.invalidToken == null
                ? null
                : l10n.hexInvalid(result.invalidToken!),
            helperText: result.paddedOddByte ? l10n.hexOddBytes : null,
            helperMaxLines: 2,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (registers.isEmpty)
          Padding(padding: const EdgeInsets.all(12), child: Text(l10n.hexEmpty))
        else ...[
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.hexBytesLabel, style: theme.textTheme.labelMedium),
                  SelectableText(formatHexBytes(result.bytes), style: mono),
                  const SizedBox(height: 8),
                  Text(
                    l10n.hexRegistersLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                  SelectableText(
                    registers.map((r) => '${formatHex(r)} ($r)').join('  '),
                    key: const Key('hex.registers'),
                    style: mono,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.labelAscii, style: theme.textTheme.labelMedium),
                  SelectableText(
                    '"${ValueFormatter.format(decodeText(result.bytes))}"',
                    style: mono,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: InterpretationMatrixTable(
              matrix: InterpretationMatrix.compute(registers),
              highlightPlausible: highlight,
              allowAddToMap: false,
              onCellAction: (row, cell, action) =>
                  _copy(ValueFormatter.format(cell.value)),
            ),
          ),
          const SizedBox(height: 12),
          _customOrderCard(context, result),
        ],
        const SizedBox(height: 12),
        _encoderCard(context),
      ],
    );
  }

  Widget _customOrderCard(BuildContext context, HexInputResult input) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    String output;
    try {
      final order = ByteOrder.parse(_pattern.text);
      final type = DataType.values.firstWhere(
        (t) => t == _patternType && t.byteWidth == order.width,
        orElse: () => throw FormatException(order.pattern),
      );
      output = ValueFormatter.format(decodeValue(input.bytes, type, order));
    } on FormatException {
      output = l10n.invalidValue;
    }
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hexCustomOrder, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<DataType>(
                    isExpanded: true,
                    initialValue: _patternType,
                    decoration: InputDecoration(labelText: l10n.fieldType),
                    items: [
                      for (final t in DataType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(t.technicalName),
                        ),
                    ],
                    onChanged: (t) => setState(() => _patternType = t!),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    key: const Key('hex.pattern'),
                    controller: _pattern,
                    style: mono,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.hexPattern,
                      hintText: l10n.hexPatternHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SelectableText(
                  output,
                  key: const Key('hex.customResult'),
                  style: theme.textTheme.titleMedium!.mono,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _encoderCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final orders = byteOrdersFor(_encodeType.byteWidth);
    if (!orders.any((o) => o.pattern == _encodeOrder)) {
      _encodeOrder = orders.first.pattern;
    }
    List<int>? registers;
    String? error;
    try {
      registers = bytesToRegisters(
        encodeValue(
          _encodeType,
          ByteOrder.parse(_encodeOrder),
          _encodeValue.text,
        ),
      );
    } on FormatException {
      error = l10n.invalidValue;
    }
    final registerText = registers
        ?.map((r) => formatHex(r, prefix: false))
        .join(' ');

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hexEncoder, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<DataType>(
                    key: const Key('hex.encodeType'),
                    isExpanded: true,
                    initialValue: _encodeType,
                    decoration: InputDecoration(labelText: l10n.fieldType),
                    items: [
                      for (final t in DataType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(t.technicalName),
                        ),
                    ],
                    onChanged: (t) => setState(() => _encodeType = t!),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('hex.encodeOrder.${_encodeType.byteWidth}'),
                    isExpanded: true,
                    initialValue: _encodeOrder,
                    decoration: InputDecoration(labelText: l10n.fieldByteOrder),
                    items: [
                      for (final o in orders)
                        DropdownMenuItem(
                          value: o.pattern,
                          child: Text(o.pattern, style: mono),
                        ),
                    ],
                    onChanged: (o) => setState(() => _encodeOrder = o!),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    key: const Key('hex.encodeValue'),
                    controller: _encodeValue,
                    style: mono,
                    decoration: InputDecoration(
                      labelText: l10n.fieldValue,
                      helperText: l10n.hexEncodeHint,
                      errorText: error,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (registers != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                registerText!,
                key: const Key('hex.encoded'),
                style: theme.textTheme.titleMedium!.mono,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _copy(registerText),
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.hexCopyRegisters),
                  ),
                  TextButton.icon(
                    key: const Key('hex.useAsInput'),
                    onPressed: () => _useAsInput(registers!),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l10n.hexUseAsInput),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
