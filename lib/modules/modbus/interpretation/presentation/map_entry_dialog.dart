import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/request_panel.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';

/// Edits [initial] (existing entry or a prefilled draft); returns the result
/// or `null` if cancelled. [isNew] controls the title.
Future<RegisterMapEntry?> showMapEntryDialog(
  BuildContext context, {
  required RegisterMapEntry initial,
  required bool isNew,
}) => showDialog<RegisterMapEntry>(
  context: context,
  builder: (_) => _MapEntryDialog(initial: initial, isNew: isNew),
);

/// Byte orders offered for a width: the four families plus the extended
/// 64-bit layouts, without duplicates.
List<ByteOrder> byteOrdersFor(int width) {
  final orders = <ByteOrder>{
    for (final family in ByteOrderFamily.values) ByteOrder.of(family, width),
    if (width == 8) ...ByteOrder.extended64,
  };
  return orders.toList();
}

const _text = 'text';
const _bit = 'bit';

class _MapEntryDialog extends ConsumerStatefulWidget {
  const new({required this.initial, required this.isNew});

  final RegisterMapEntry initial;
  final bool isNew;

  @override
  ConsumerState<_MapEntryDialog> createState() => _MapEntryDialogState();
}

class _MapEntryDialogState extends ConsumerState<_MapEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.initial.label);
  late final _unit = TextEditingController(text: widget.initial.unit);
  late final _description = TextEditingController(
    text: widget.initial.description,
  );
  late final _address = TextEditingController();
  late final _textRegisters = TextEditingController();
  late final _bitIndex = TextEditingController();
  late final _factor = TextEditingController();
  late final _offset = TextEditingController();
  late final _decimals = TextEditingController();

  late RegisterTable _table = widget.initial.table;
  late String _type;
  late String _order;
  bool _textSwap = false;
  TextEncoding _encoding = TextEncoding.ascii;

  @override
  void initState() {
    super.initState();
    final entry = widget.initial;
    _address.text = ModbusAddress.format(
      entry.address,
      entry.table,
      ref.read(settingsControllerProvider).addressingMode,
    );
    switch (entry.format) {
      case NumericFormat(:final type, :final order):
        _type = type.name;
        _order = order.pattern;
        _textRegisters.text = '8';
      case TextFormat(:final registerCount, :final swapBytes, :final encoding):
        _type = _text;
        _order = 'AB';
        _textRegisters.text = '$registerCount';
        _textSwap = swapBytes;
        _encoding = encoding;
      case BitFormat(:final bit):
        _type = _bit;
        _order = 'AB';
        _bitIndex.text = '${bit ?? 0}';
        _textRegisters.text = '8';
    }
    final scaling = entry.scaling;
    _factor.text = _number(scaling.factor);
    _offset.text = _number(scaling.offset);
    _decimals.text = scaling.decimals?.toString() ?? '';
  }

  static String _number(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    for (final c in [
      _label,
      _unit,
      _description,
      _address,
      _textRegisters,
      _bitIndex,
      _factor,
      _offset,
      _decimals,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  DataType? get _dataType =>
      _type == _text || _type == _bit ? null : DataType.values.byName(_type);

  void _setTable(RegisterTable table) => setState(() {
    _table = table;
    if (table.isBitTable) _type = _bit;
  });

  void _setType(String type) => setState(() {
    _type = type;
    final dataType = _dataType;
    if (dataType != null &&
        !byteOrdersFor(dataType.byteWidth).any((o) => o.pattern == _order)) {
      _order = byteOrdersFor(dataType.byteWidth).first.pattern;
    }
  });

  ValueFormat _buildFormat() {
    final dataType = _dataType;
    if (dataType != null) {
      return NumericFormat(dataType, ByteOrder.parse(_order));
    }
    if (_type == _text) {
      return TextFormat(
        registerCount: int.parse(_textRegisters.text),
        swapBytes: _textSwap,
        encoding: _encoding,
      );
    }
    return BitFormat(bit: _table.isBitTable ? null : int.parse(_bitIndex.text));
  }

  double? _parseDouble(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final mode = ref.read(settingsControllerProvider).addressingMode;
    final decimals = _decimals.text.trim();
    final format = _buildFormat();
    final entry = RegisterMapEntry(
      id: widget.initial.id,
      table: _table,
      address: ModbusAddress.parse(_address.text, _table, mode),
      format: format,
      label: _label.text.trim(),
      unit: _unit.text.trim(),
      description: _description.text.trim(),
      scaling: format is NumericFormat
          ? Scaling(
              factor: _parseDouble(_factor.text) ?? 1,
              offset: _parseDouble(_offset.text) ?? 0,
              decimals: decimals.isEmpty ? null : int.parse(decimals),
            )
          : Scaling.identity,
    );
    Navigator.pop(context, entry);
  }

  String? _validateAddress(String? text) {
    final l10n = context.l10n;
    final mode = ref.read(settingsControllerProvider).addressingMode;
    try {
      final address = ModbusAddress.parse(text ?? '', _table, mode);
      final count = _type == _text
          ? int.tryParse(_textRegisters.text) ?? 1
          : _dataType?.registerCount ?? 1;
      if (address + count - 1 > maxProtocolAddress) {
        return l10n.rangeExceedsAddressSpace;
      }
      return null;
    } on FormatException {
      return l10n.invalidValue;
    }
  }

  String? Function(String?) _intRange(int min, int max) => (text) {
    final value = int.tryParse(text?.trim() ?? '');
    return value == null || value < min || value > max
        ? context.l10n.validationRange(min, max)
        : null;
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mono = Theme.of(context).textTheme.bodyMedium!.mono;
    final dataType = _dataType;
    final typeItems = [
      if (!_table.isBitTable)
        for (final t in DataType.values)
          DropdownMenuItem(value: t.name, child: Text(t.technicalName)),
      if (!_table.isBitTable)
        DropdownMenuItem(value: _text, child: Text(l10n.typeText)),
      DropdownMenuItem(value: _bit, child: Text(l10n.typeBit)),
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
      },
      child: AlertDialog(
        title: Text(
          widget.isNew ? l10n.mapEntryNewTitle : l10n.mapEntryEditTitle,
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('mapEntry.label'),
                    controller: _label,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.fieldLabel),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unit,
                          decoration: InputDecoration(
                            labelText: l10n.fieldUnit,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _description,
                          decoration: InputDecoration(
                            labelText: l10n.fieldDescription,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<RegisterTable>(
                          isExpanded: true,
                          initialValue: _table,
                          decoration: InputDecoration(
                            labelText: l10n.fieldTable,
                          ),
                          items: [
                            for (final t in RegisterTable.values)
                              DropdownMenuItem(
                                value: t,
                                child: Text(t.label(l10n)),
                              ),
                          ],
                          onChanged: (t) => _setTable(t!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: const Key('mapEntry.address'),
                          controller: _address,
                          style: mono,
                          decoration: InputDecoration(
                            labelText: l10n.fieldAddress,
                          ),
                          validator: _validateAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('mapEntry.type.$_table'),
                          isExpanded: true,
                          initialValue: _type,
                          decoration: InputDecoration(
                            labelText: l10n.fieldType,
                          ),
                          items: typeItems,
                          onChanged: (t) => _setType(t!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _formatDetail(l10n, dataType, mono)),
                    ],
                  ),
                  if (_type == _text) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.textSwapBytes),
                      value: _textSwap,
                      onChanged: (v) => setState(() => _textSwap = v!),
                    ),
                  ],
                  if (dataType != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _factor,
                            style: mono,
                            decoration: InputDecoration(
                              labelText: l10n.fieldFactor,
                            ),
                            validator: (t) => _parseDouble(t ?? '') == null
                                ? l10n.validationNumber
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _offset,
                            style: mono,
                            decoration: InputDecoration(
                              labelText: l10n.fieldOffset,
                            ),
                            validator: (t) => _parseDouble(t ?? '') == null
                                ? l10n.validationNumber
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _decimals,
                            style: mono,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.fieldDecimals,
                            ),
                            validator: (t) => (t ?? '').trim().isEmpty
                                ? null
                                : _intRange(0, 10)(t),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('mapEntry.save'),
            onPressed: _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }

  Widget _formatDetail(
    AppLocalizations l10n,
    DataType? dataType,
    TextStyle mono,
  ) {
    if (dataType != null) {
      return DropdownButtonFormField<String>(
        key: ValueKey('mapEntry.order.${dataType.byteWidth}'),
        isExpanded: true,
        initialValue: _order,
        decoration: InputDecoration(labelText: l10n.fieldByteOrder),
        items: [
          for (final order in byteOrdersFor(dataType.byteWidth))
            DropdownMenuItem(
              value: order.pattern,
              child: Text(order.pattern, style: mono),
            ),
        ],
        onChanged: (o) => setState(() => _order = o!),
      );
    }
    if (_type == _text) {
      return TextFormField(
        controller: _textRegisters,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.fieldTextRegisters),
        validator: _intRange(1, TextFormat.maxRegisters),
      );
    }
    if (_table.isBitTable) return const SizedBox.shrink();
    return TextFormField(
      controller: _bitIndex,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: l10n.fieldBit),
      validator: _intRange(0, 15),
    );
  }
}

/// Saves [entry] to the current profile's map; returns `false` if there
/// is no profile to store it under.
Future<bool> saveMapEntry(WidgetRef ref, RegisterMapEntry entry) async {
  final profileId = ref.read(currentProfileIdProvider);
  if (profileId == null) return false;
  await ref
      .read(registerMapControllerProvider.notifier)
      .saveEntry(profileId, entry);
  return true;
}
