import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_address.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';

String readShortcutLabel() =>
    defaultTargetPlatform == TargetPlatform.macOS ? '⌘R' : 'Ctrl+R';

extension RegisterTableLabel on RegisterTable {
  String label(AppLocalizations l10n) => switch (this) {
    RegisterTable.coils => l10n.tableCoils,
    RegisterTable.discreteInputs => l10n.tableDiscreteInputs,
    RegisterTable.inputRegisters => l10n.tableInputRegisters,
    RegisterTable.holdingRegisters => l10n.tableHoldingRegisters,
  };
}

/// Table, address range, unit, read/poll controls and write protection.
class RequestPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RequestPanel> createState() => _RequestPanelState();
}

class _RequestPanelState extends ConsumerState<RequestPanel> {
  final _address = TextEditingController();
  final _count = TextEditingController();
  final _unitId = TextEditingController();
  final _interval = TextEditingController();
  String? _addressError;
  String? _countError;
  String? _unitError;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registersControllerProvider);
    _syncAddressText();
    _count.text = '${state.query.count}';
    _unitId.text = state.query.unitId?.toString() ?? '';
    _interval.text = '${state.pollInterval.inMilliseconds}';
  }

  @override
  void dispose() {
    _address.dispose();
    _count.dispose();
    _unitId.dispose();
    _interval.dispose();
    super.dispose();
  }

  AddressingMode get _mode =>
      ref.read(settingsControllerProvider).addressingMode;
  RegisterQuery get _query => ref.read(registersControllerProvider).query;
  RegistersController get _controller =>
      ref.read(registersControllerProvider.notifier);

  void _syncAddressText() {
    _address.text = ModbusAddress.format(_query.address, _query.table, _mode);
    _addressError = null;
  }

  void _onTableChanged(RegisterTable table) {
    _controller.setQuery(_query.copyWith(table: table));
    setState(() {
      _syncAddressText();
      _count.text = '${ref.read(registersControllerProvider).query.count}';
    });
  }

  void _onAddressChanged(String text) {
    final l10n = context.l10n;
    final int address;
    try {
      address = ModbusAddress.parse(text, _query.table, _mode);
    } on FormatException {
      setState(() => _addressError = l10n.invalidValue);
      return;
    }
    if (address + _query.count - 1 > maxProtocolAddress) {
      setState(() => _addressError = l10n.rangeExceedsAddressSpace);
      return;
    }
    _controller.setQuery(_query.copyWith(address: address));
    setState(() => _addressError = null);
  }

  void _onCountChanged(String text) {
    final l10n = context.l10n;
    final count = int.tryParse(text);
    final max = _query.maxCount;
    if (count == null || count < 1 || count > max) {
      setState(() => _countError = l10n.validationRange(1, max));
      return;
    }
    if (_query.address + count - 1 > maxProtocolAddress) {
      setState(() => _countError = l10n.rangeExceedsAddressSpace);
      return;
    }
    _controller.setQuery(_query.copyWith(count: count));
    setState(() => _countError = null);
  }

  void _onUnitChanged(String text) {
    final l10n = context.l10n;
    if (text.trim().isEmpty) {
      _controller.setQuery(_query.copyWith(unitId: () => null));
      setState(() => _unitError = null);
      return;
    }
    final unit = int.tryParse(text);
    if (unit == null || unit < 0 || unit > 255) {
      setState(() => _unitError = l10n.validationRange(0, 255));
      return;
    }
    _controller.setQuery(_query.copyWith(unitId: () => unit));
    setState(() => _unitError = null);
  }

  void _onIntervalChanged(String text) {
    final ms = int.tryParse(text);
    if (ms != null && ms > 0) {
      _controller.setPollInterval(Duration(milliseconds: ms));
    }
  }

  bool get _inputValid =>
      _addressError == null && _countError == null && _unitError == null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(registersControllerProvider);
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.addressingMode),
    );
    final connected = ref.watch(activeClientProvider) != null;
    ref.listen(
      settingsControllerProvider.select((s) => s.addressingMode),
      (_, _) => setState(_syncAddressText),
    );

    final query = state.query;
    final mono = theme.textTheme.bodyMedium!.mono;
    final canRead = connected && _inputValid;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                String label(RegisterTable t) =>
                    '${t.label(l10n)} (${t.modiconPrefix}x)';
                // On phones the segments don't fit and the selected one
                // could scroll out of view (seen on a real screen).
                if (constraints.maxWidth < 560) {
                  return DropdownButtonFormField<RegisterTable>(
                    key: const Key('request.table'),
                    isExpanded: true,
                    initialValue: query.table,
                    decoration: InputDecoration(labelText: l10n.fieldTable),
                    items: [
                      for (final table in RegisterTable.values)
                        DropdownMenuItem(
                          value: table,
                          child: Text(label(table)),
                        ),
                    ],
                    onChanged: state.isPolling
                        ? null
                        : (t) => _onTableChanged(t!),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<RegisterTable>(
                    key: const Key('request.table'),
                    showSelectedIcon: false,
                    segments: [
                      for (final table in RegisterTable.values)
                        ButtonSegment(value: table, label: Text(label(table))),
                    ],
                    selected: {query.table},
                    onSelectionChanged: state.isPolling
                        ? null
                        : (s) => _onTableChanged(s.single),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: TextField(
                    key: const Key('request.address'),
                    controller: _address,
                    style: mono,
                    decoration: InputDecoration(
                      labelText: l10n.fieldStartAddress,
                      errorText: _addressError,
                      helperText: mode == AddressingMode.oneBased
                          ? l10n.addressHintProtocol(
                              '${query.address} (${formatHex(query.address)})',
                            )
                          : formatHex(query.address),
                      helperStyle: theme.textTheme.bodySmall!.mono,
                      helperMaxLines: 2,
                    ),
                    onChanged: _onAddressChanged,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    key: const Key('request.count'),
                    controller: _count,
                    style: mono,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.fieldCount,
                      errorText: _countError,
                      helperText: '≤ ${query.maxCount}',
                    ),
                    onChanged: _onCountChanged,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _unitId,
                    style: mono,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.fieldUnitIdOverride,
                      helperText: l10n.fieldUnitIdOverrideHint,
                      helperMaxLines: 2,
                      errorText: _unitError,
                    ),
                    onChanged: _onUnitChanged,
                  ),
                ),
                Tooltip(
                  message: l10n.addressModeTooltip,
                  child: Chip(
                    avatar: const Icon(Icons.pin_outlined, size: 18),
                    label: Text(
                      mode == AddressingMode.oneBased
                          ? l10n.addressingOneBased
                          : l10n.addressingZeroBased,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: l10n.actionReadTooltip(readShortcutLabel()),
                  child: FilledButton.icon(
                    key: const Key('request.read'),
                    onPressed: canRead && !state.isPolling && !state.isBusy
                        ? _controller.read
                        : null,
                    icon: state.isBusy && !state.isPolling
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(l10n.actionRead),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _interval,
                    style: mono,
                    enabled: !state.isPolling,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.fieldPollInterval,
                    ),
                    onChanged: _onIntervalChanged,
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const Key('request.poll'),
                  onPressed: canRead || state.isPolling
                      ? _controller.togglePolling
                      : null,
                  icon: Icon(state.isPolling ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    state.isPolling
                        ? l10n.actionStopPolling
                        : l10n.actionStartPolling,
                  ),
                ),
                if (query.table.isWritable)
                  Tooltip(
                    message: l10n.writeUnlockTooltip,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          key: const Key('request.writeUnlock'),
                          value: state.writeUnlocked,
                          onChanged: (v) =>
                              _controller.setWriteUnlocked(unlocked: v),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          state.writeUnlocked ? Icons.lock_open : Icons.lock,
                          size: 18,
                          color: state.writeUnlocked
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.writeUnlockLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
