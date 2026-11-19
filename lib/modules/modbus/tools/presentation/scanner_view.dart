import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/request_panel.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/scanner_controller.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

class ScannerView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends ConsumerState<ScannerView> {
  ScanMode _mode = ScanMode.slaveIds;
  RegisterTable _table = RegisterTable.holdingRegisters;
  final _from = TextEditingController(text: '1');
  final _to = TextEditingController(text: '247');
  final _address = TextEditingController();
  final _timeout = TextEditingController(text: '100');
  final _blockSize = TextEditingController(text: '10');
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _resetAddressFields();
  }

  @override
  void dispose() {
    for (final c in [_from, _to, _address, _timeout, _blockSize]) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetAddressFields() {
    final mode = ref.read(settingsControllerProvider).addressingMode;
    _address.text = ModbusAddress.format(0, _table, mode);
    if (_mode == ScanMode.registers) {
      _from.text = ModbusAddress.format(0, _table, mode);
      _to.text = ModbusAddress.format(99, _table, mode);
    }
  }

  void _setMode(ScanMode mode) => setState(() {
    _mode = mode;
    if (mode == ScanMode.slaveIds) {
      _from.text = '1';
      _to.text = '247';
    }
    _resetAddressFields();
  });

  void _start() {
    final l10n = context.l10n;
    final mode = ref.read(settingsControllerProvider).addressingMode;
    final timeout = int.tryParse(_timeout.text);
    if (timeout == null || timeout < 5 || timeout > 10000) {
      setState(() => _inputError = l10n.validationRange(5, 10000));
      return;
    }
    final scanner = ref.read(scannerControllerProvider.notifier);
    try {
      if (_mode == ScanMode.slaveIds) {
        final from = int.parse(_from.text);
        final to = int.parse(_to.text);
        if (from < 1 || to > 255 || from > to) throw const FormatException();
        final address = ModbusAddress.parse(_address.text, _table, mode);
        setState(() => _inputError = null);
        unawaited(
          scanner.scanSlaves(
            from: from,
            to: to,
            table: _table,
            address: address,
            timeout: Duration(milliseconds: timeout),
          ),
        );
      } else {
        final from = ModbusAddress.parse(_from.text, _table, mode);
        final to = ModbusAddress.parse(_to.text, _table, mode);
        final block = int.parse(_blockSize.text);
        if (from > to || block < 1 || block > 125) {
          throw const FormatException();
        }
        setState(() => _inputError = null);
        unawaited(
          scanner.scanRegisters(
            table: _table,
            from: from,
            to: to,
            timeout: Duration(milliseconds: timeout),
            blockSize: block,
          ),
        );
      }
    } on FormatException {
      setState(() => _inputError = l10n.invalidValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final state = ref.watch(scannerControllerProvider);
    final client = ref.watch(activeClientProvider);
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.addressingMode),
    );
    final idCount =
        (int.tryParse(_to.text) ?? 0) - (int.tryParse(_from.text) ?? 0) + 1;
    final timeoutMs = int.tryParse(_timeout.text) ?? 0;

    Widget field(
      TextEditingController c,
      String label, {
      double width = 120,
      Key? key,
    }) => SizedBox(
      width: width,
      child: TextField(
        key: key,
        controller: c,
        style: mono,
        enabled: !state.isRunning,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );

    final error = state.error;
    final elapsed = state.finishedAt != null && state.startedAt != null
        ? state.finishedAt!.difference(state.startedAt!)
        : null;

    return ListView(
      key: const Key('scanner.view'),
      padding: const EdgeInsets.all(12),
      children: [
        SegmentedButton<ScanMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ScanMode.slaveIds,
              label: Text(l10n.scanModeSlaves),
            ),
            ButtonSegment(
              value: ScanMode.registers,
              label: Text(l10n.scanModeRegisters),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: state.isRunning
              ? null
              : (s) => _setMode(s.single),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<RegisterTable>(
                isExpanded: true,
                initialValue: _table,
                decoration: InputDecoration(labelText: l10n.fieldTable),
                items: [
                  for (final t in RegisterTable.values)
                    DropdownMenuItem(value: t, child: Text(t.label(l10n))),
                ],
                onChanged: state.isRunning
                    ? null
                    : (t) => setState(() {
                        _table = t!;
                        _resetAddressFields();
                      }),
              ),
            ),
            field(_from, l10n.scanFrom, key: const Key('scanner.from')),
            field(_to, l10n.scanTo, key: const Key('scanner.to')),
            if (_mode == ScanMode.slaveIds)
              field(
                _address,
                l10n.scanProbeAddress,
                width: 140,
                key: const Key('scanner.address'),
              ),
            if (_mode == ScanMode.registers)
              field(_blockSize, l10n.scanBlockSize),
            field(
              _timeout,
              l10n.scanTimeout,
              key: const Key('scanner.timeout'),
            ),
          ],
        ),
        if (_inputError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _inputError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        if (_mode == ScanMode.slaveIds && idCount > 0)
          Text(
            l10n.scanSlowHint(
              idCount,
              (idCount * timeoutMs / 1000).toStringAsFixed(0),
            ),
            style: theme.textTheme.bodySmall,
          ),
        if (_mode == ScanMode.slaveIds && client?.frameKind == FrameKind.tcp)
          Text(l10n.scanTcpHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            if (state.isRunning)
              OutlinedButton.icon(
                key: const Key('scanner.cancel'),
                onPressed: ref.read(scannerControllerProvider.notifier).cancel,
                icon: const Icon(Icons.stop),
                label: Text(l10n.actionCancel),
              )
            else
              FilledButton.icon(
                key: const Key('scanner.start'),
                onPressed: client == null ? null : _start,
                icon: const Icon(Icons.radar),
                label: Text(l10n.scanStart),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                [
                  if (state.total > 0)
                    l10n.scanProgress(
                      state.done,
                      state.total,
                      state.hits.length,
                    ),
                  if (state.cancelled) l10n.scanCancelled,
                  if (!state.isRunning && !state.cancelled && elapsed != null)
                    l10n.scanFinished(
                      (elapsed.inMilliseconds / 1000).toStringAsFixed(1),
                    ),
                ].join(' · '),
                key: const Key('scanner.status'),
              ),
            ),
          ],
        ),
        if (state.isRunning || state.total > 0) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: state.progress),
        ],
        if (client == null) ...[
          const SizedBox(height: 12),
          Text(l10n.errorNotConnectedHint),
        ],
        if (error != null && error is! NotConnectedError) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final text = describeError(l10n, error);
              return ErrorPanel(
                title: text.title,
                hint: text.hint,
                detail: text.detail,
                dense: true,
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        if (!state.isRunning && state.total > 0 && state.hits.isEmpty)
          Text(l10n.scanNoResults),
        for (final hit in state.hits)
          ListTile(
            key: ValueKey('scan.hit.${hit.key}'),
            dense: true,
            leading: Icon(
              hit.exceptionCode == null
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
            ),
            title: Text(
              state.mode == ScanMode.slaveIds
                  ? l10n.scanUnit(hit.key)
                  : ModbusAddress.format(hit.key, _table, mode),
              style: mono,
            ),
            subtitle: Text(
              hit.exceptionCode != null
                  ? l10n.scanException(_exceptionLabel(hit.exceptionCode!))
                  : '${formatHex(hit.value ?? 0)} (${hit.value})',
              style: mono,
            ),
            trailing: hit.latency == null
                ? null
                : Text('${hit.latency!.inMilliseconds} ms', style: mono),
            onLongPress: () =>
                Clipboard.setData(ClipboardData(text: '${hit.key}')),
          ),
      ],
    );
  }
}

String _exceptionLabel(int code) {
  final name = ModbusExceptionCode.fromCode(code)?.specName;
  final hex = formatHex(code, digits: 2);
  return name == null ? hex : '$hex $name';
}
