import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_breakdown.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_address.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/registers/domain/value_input.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/registers/presentation/write_description.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';

/// Confirms (if enabled), sends and reports a write request.
Future<void> performWrite(
  BuildContext context,
  WidgetRef ref,
  ModbusRequest request,
) async {
  final l10n = context.l10n;
  final settings = ref.read(settingsControllerProvider);
  final summary = describeWrite(request, settings.addressingMode);
  final messenger = ScaffoldMessenger.of(context);

  if (settings.confirmWrites) {
    final unit =
        ref.read(registersControllerProvider).query.unitId ??
        ref.read(connectionControllerProvider).profile?.config.options.unitId ??
        1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(l10n.confirmWriteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmWriteBody(unit)),
            const SizedBox(height: 12),
            SelectableText(
              summary,
              style: Theme.of(context).textTheme.bodyMedium!.mono,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('confirmWrite.ok'),
            autofocus: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionWrite),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }

  try {
    await ref.read(registersControllerProvider.notifier).write(request);
    messenger.showSnackBar(SnackBar(content: Text(l10n.writeSuccess(summary))));
  } on Object catch (e) {
    final text = describeError(l10n, e);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('${text.title}\n${text.hint}'),
      ),
    );
  }
}

/// Single holding register: value field plus clickable bits.
Future<ModbusRequest?> showWriteRegisterDialog(
  BuildContext context, {
  required int address,
  required String displayAddress,
  required int currentValue,
}) => showDialog<ModbusRequest>(
  context: context,
  builder: (_) => _WriteRegisterDialog(
    address: address,
    displayAddress: displayAddress,
    currentValue: currentValue,
  ),
);

class _WriteRegisterDialog extends StatefulWidget {
  const new({
    required this.address,
    required this.displayAddress,
    required this.currentValue,
  });

  final int address;
  final String displayAddress;
  final int currentValue;

  @override
  State<_WriteRegisterDialog> createState() => _WriteRegisterDialogState();
}

class _WriteRegisterDialogState extends State<_WriteRegisterDialog> {
  late final _text = TextEditingController(text: '${widget.currentValue}');
  late int? _value = widget.currentValue;
  bool _useFc16 = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setBit(int bit, {required bool on}) {
    final value = RegisterBreakdown(_value ?? 0).withBit(bit, value: on);
    setState(() {
      _value = value;
      _text.text = '$value';
    });
  }

  void _submit() {
    final value = _value;
    if (value == null) return;
    Navigator.pop(
      context,
      _useFc16
          ? WriteMultipleRegistersRequest(
              address: widget.address,
              values: [value],
            )
          : WriteSingleRegisterRequest(address: widget.address, value: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = _value;
    final breakdown = value == null ? null : RegisterBreakdown(value);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: AlertDialog(
        title: Text(l10n.writeRegisterTitle(widget.displayAddress)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('writeRegister.value'),
                controller: _text,
                autofocus: true,
                style: theme.textTheme.bodyLarge!.mono,
                decoration: InputDecoration(
                  labelText: l10n.fieldValue,
                  helperText: l10n.valueFormatsHint,
                  errorText: value == null ? l10n.invalidValue : null,
                ),
                onChanged: (t) =>
                    setState(() => _value = parseRegisterValue(t)),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              if (breakdown != null)
                Text(
                  '${breakdown.hex} · ${breakdown.unsigned} · '
                  '${breakdown.signed} · ${breakdown.binary}',
                  style: theme.textTheme.bodySmall!.mono,
                ),
              const SizedBox(height: 16),
              Text(l10n.bitsLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var bit = 15; bit >= 0; bit--)
                    FilterChip(
                      key: Key('writeRegister.bit$bit'),
                      label: Text('$bit'),
                      showCheckmark: false,
                      tooltip: 'Bit $bit',
                      selected: breakdown?.bit(bit) ?? false,
                      onSelected: (on) => _setBit(bit, on: on),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.useFc16),
                value: _useFc16,
                onChanged: (v) => setState(() => _useFc16 = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('writeRegister.submit'),
            onPressed: value == null ? null : _submit,
            child: Text(l10n.actionWrite),
          ),
        ],
      ),
    );
  }
}

/// FC15/FC16 for a list of values starting at an address.
Future<ModbusRequest?> showWriteMultipleDialog(
  BuildContext context,
  WidgetRef ref, {
  required RegisterTable table,
  required int startAddress,
}) => showDialog<ModbusRequest>(
  context: context,
  builder: (_) =>
      _WriteMultipleDialog(table: table, startAddress: startAddress),
);

class _WriteMultipleDialog extends ConsumerStatefulWidget {
  const new({required this.table, required this.startAddress});

  final RegisterTable table;
  final int startAddress;

  @override
  ConsumerState<_WriteMultipleDialog> createState() =>
      _WriteMultipleDialogState();
}

class _WriteMultipleDialogState extends ConsumerState<_WriteMultipleDialog> {
  late final _address = TextEditingController(
    text: ModbusAddress.format(
      widget.startAddress,
      widget.table,
      ref.read(settingsControllerProvider).addressingMode,
    ),
  );
  final _values = TextEditingController();
  String? _addressError;
  String? _valuesError;

  bool get _isCoils => widget.table == RegisterTable.coils;

  @override
  void dispose() {
    _address.dispose();
    _values.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final mode = ref.read(settingsControllerProvider).addressingMode;
    int? address;
    try {
      address = ModbusAddress.parse(_address.text, widget.table, mode);
    } on FormatException {
      address = null;
    }
    final coils = _isCoils ? parseCoilList(_values.text) : null;
    final registers = _isCoils ? null : parseRegisterList(_values.text);
    final count = coils?.length ?? registers?.length;
    final max = _isCoils
        ? ModbusLimits.maxWriteCoils
        : ModbusLimits.maxWriteRegisters;

    setState(() {
      _addressError = address == null ? l10n.invalidValue : null;
      _valuesError = count == null
          ? l10n.invalidValue
          : count > max
          ? l10n.tooManyValues(max)
          : address != null && address + count - 1 > maxProtocolAddress
          ? l10n.rangeExceedsAddressSpace
          : null;
    });
    if (_addressError != null || _valuesError != null) return;
    Navigator.pop(
      context,
      _isCoils
          ? WriteMultipleCoilsRequest(address: address!, values: coils!)
          : WriteMultipleRegistersRequest(
              address: address!,
              values: registers!,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mono = Theme.of(context).textTheme.bodyLarge!.mono;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: AlertDialog(
        title: Text(l10n.writeMultipleTitle),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _address,
                style: mono,
                decoration: InputDecoration(
                  labelText: l10n.fieldStartAddress,
                  errorText: _addressError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('writeMultiple.values'),
                controller: _values,
                autofocus: true,
                minLines: 2,
                maxLines: 6,
                style: mono,
                decoration: InputDecoration(
                  labelText: l10n.fieldValues,
                  helperText: _isCoils
                      ? l10n.coilValuesHint
                      : l10n.registerValuesHint,
                  helperMaxLines: 2,
                  errorText: _valuesError,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('writeMultiple.submit'),
            onPressed: _submit,
            child: Text(l10n.actionWrite),
          ),
        ],
      ),
    );
  }
}
