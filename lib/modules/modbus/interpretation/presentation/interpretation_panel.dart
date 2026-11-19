import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_breakdown.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/interpretation_input.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/map_entry_dialog.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/write_dialogs.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/shared/interpretation/domain/matrix_export.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/shared/interpretation/presentation/interpretation_settings.dart';
import 'package:modbus_explorer/shared/interpretation/presentation/matrix_table.dart';

/// Breakdown of the selected register, its bits, the full type × byte
/// order matrix, text and scaling.
class InterpretationPanel extends ConsumerWidget {
  const new({this.scrollController, super.key});

  /// Provided by a draggable bottom sheet on phones.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final input = ref.watch(interpretationInputProvider);
    final matrix = ref.watch(interpretationMatrixProvider);
    final table = ref.watch(
      registersControllerProvider.select((s) => s.snapshot?.table),
    );
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.addressingMode),
    );

    if (input == null || matrix == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            table != null && table.isBitTable
                ? l10n.interpretationBitTables
                : l10n.interpretationNoData,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final first = ModbusAddress.format(input.start, input.table, mode);
    final range = input.selectionLength == 1
        ? first
        : '$first…${ModbusAddress.format(input.end, input.table, mode)}';

    return ListView(
      key: const Key('interpretation.panel'),
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.interpretationTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Text(
          '${l10n.interpretationSelection(range, input.selectionLength)} · '
          '${l10n.interpretationHint}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _BreakdownCard(
          address: input.start,
          displayAddress: first,
          table: input.table,
          value: input.registers.first,
        ),
        const SizedBox(height: 12),
        _MatrixCard(matrix: matrix, input: input),
        const SizedBox(height: 12),
        const _ScalingCard(),
        const SizedBox(height: 12),
        _TextCard(input: input),
      ],
    );
  }
}

class _BreakdownCard extends ConsumerWidget {
  const new({
    required this.address,
    required this.displayAddress,
    required this.table,
    required this.value,
  });

  final int address;
  final String displayAddress;
  final RegisterTable table;
  final int value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final r = RegisterBreakdown(value);
    final canWrite =
        table == RegisterTable.holdingRegisters &&
        ref.watch(registersControllerProvider.select((s) => s.writeUnlocked)) &&
        ref.watch(activeClientProvider) != null;

    Widget pair(String label, String text) => Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          SelectableText(text, style: mono),
        ],
      ),
    );

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sectionRegister(displayAddress),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                pair(l10n.columnHex, r.hex),
                pair(l10n.columnUnsigned, '${r.unsigned}'),
                pair(l10n.columnSigned, '${r.signed}'),
                pair(l10n.columnBinary, r.binary),
                pair(
                  l10n.labelHighByte,
                  '${formatHex(r.highByte, digits: 2)} · ${r.highByte} · '
                  '${r.highByteSigned}',
                ),
                pair(
                  l10n.labelLowByte,
                  '${formatHex(r.lowByte, digits: 2)} · ${r.lowByte} · '
                  '${r.lowByteSigned}',
                ),
                pair(l10n.labelAscii, r.ascii),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var bit = 15; bit >= 0; bit--)
                  FilterChip(
                    key: Key('bits.$bit'),
                    label: Text('$bit', style: mono),
                    showCheckmark: false,
                    tooltip: 'Bit $bit',
                    selected: r.bit(bit),
                    onSelected: canWrite
                        ? (on) => performWrite(
                            context,
                            ref,
                            WriteSingleRegisterRequest(
                              address: address,
                              value: r.withBit(bit, value: on),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
            if (table == RegisterTable.holdingRegisters && !canWrite)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.bitsReadOnlyHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MatrixCard extends ConsumerWidget {
  const new({required this.matrix, required this.input});

  final InterpretationMatrix matrix;
  final InterpretationInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scaling = ref.watch(
      interpretationSettingsProvider.select((s) => s.scaling),
    );
    final highlight = ref.watch(
      settingsControllerProvider.select((s) => s.highlightPlausible),
    );

    Future<void> copy(String text, String message) async {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showReplacing(message);
      }
    }

    Future<void> addToMap(MatrixRow row, MatrixCell cell) async {
      final messenger = ScaffoldMessenger.of(context);
      final entry = await showMapEntryDialog(
        context,
        isNew: true,
        initial: RegisterMapEntry(
          id: RegisterMapController.newEntryId(),
          table: input.table,
          address: input.start,
          format: NumericFormat(row.type, cell.order),
          scaling: scaling,
        ),
      );
      if (entry == null) return;
      final saved = await saveMapEntry(ref, entry);
      messenger.showReplacing(
        saved
            ? l10n.mapEntrySaved(
                entry.label.isEmpty ? l10n.mapUnnamed : entry.label,
              )
            : l10n.mapNoProfile,
      );
    }

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sectionMatrix,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: const Key('matrix.copyTsv'),
                  tooltip: l10n.actionCopyTable,
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () => copy(
                    matrixToDelimited(matrix, scaling: scaling),
                    l10n.copiedTable,
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionCopyCsv,
                  icon: const Icon(Icons.table_view_outlined),
                  onPressed: () => copy(
                    matrixToDelimited(
                      matrix,
                      scaling: scaling,
                      separator: csvSeparator,
                    ),
                    l10n.copiedTable,
                  ),
                ),
              ],
            ),
          ),
          InterpretationMatrixTable(
            matrix: matrix,
            scaling: scaling,
            highlightPlausible: highlight,
            onCellAction: (row, cell, action) => switch (action) {
              MatrixCellAction.copy => copy(
                ValueFormatter.format(cell.value, scaling: scaling),
                l10n.copiedValue(
                  ValueFormatter.format(cell.value, scaling: scaling),
                ),
              ),
              MatrixCellAction.addToMap => addToMap(row, cell),
            },
          ),
        ],
      ),
    );
  }
}

class _ScalingCard extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ScalingCard> createState() => _ScalingCardState();
}

class _ScalingCardState extends ConsumerState<_ScalingCard> {
  late final Scaling _initial = ref
      .read(interpretationSettingsProvider)
      .scaling;
  late final _factor = TextEditingController(text: _format(_initial.factor));
  late final _offset = TextEditingController(text: _format(_initial.offset));
  late final _decimals = TextEditingController(
    text: _initial.decimals?.toString() ?? '',
  );

  static String _format(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    _factor.dispose();
    _offset.dispose();
    _decimals.dispose();
    super.dispose();
  }

  void _apply() {
    double? parse(String t) => double.tryParse(t.trim().replaceAll(',', '.'));
    final decimals = int.tryParse(_decimals.text.trim());
    ref
        .read(interpretationSettingsProvider.notifier)
        .setScaling(
          Scaling(
            factor: parse(_factor.text) ?? 1,
            offset: parse(_offset.text) ?? 0,
            decimals: decimals != null && decimals >= 0 && decimals <= 10
                ? decimals
                : null,
          ),
        );
  }

  void _reset() {
    _factor.text = '1';
    _offset.text = '0';
    _decimals.clear();
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final scaling = ref.watch(
      interpretationSettingsProvider.select((s) => s.scaling),
    );
    Widget field(TextEditingController c, String label, Key key) => SizedBox(
      width: 120,
      child: TextField(
        key: key,
        controller: c,
        style: mono,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _apply(),
      ),
    );

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sectionScaling,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (!scaling.isIdentity)
                  TextButton(onPressed: _reset, child: Text(l10n.actionReset)),
              ],
            ),
            Text(l10n.scalingHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                field(_factor, l10n.fieldFactor, const Key('scaling.factor')),
                field(_offset, l10n.fieldOffset, const Key('scaling.offset')),
                field(
                  _decimals,
                  l10n.fieldDecimals,
                  const Key('scaling.decimals'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends ConsumerWidget {
  const new({required this.input});

  final InterpretationInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(interpretationSettingsProvider);
    final controller = ref.read(interpretationSettingsProvider.notifier);
    final value = decodeText(
      registersToBytes(input.selected),
      swapBytes: settings.textSwapBytes,
      encoding: settings.textEncoding,
    );
    final text = ValueFormatter.format(value);

    Future<void> addToMap() async {
      final messenger = ScaffoldMessenger.of(context);
      final entry = await showMapEntryDialog(
        context,
        isNew: true,
        initial: RegisterMapEntry(
          id: RegisterMapController.newEntryId(),
          table: input.table,
          address: input.start,
          format: TextFormat(
            registerCount: input.selectionLength.clamp(
              1,
              TextFormat.maxRegisters,
            ),
            swapBytes: settings.textSwapBytes,
            encoding: settings.textEncoding,
          ),
        ),
      );
      if (entry == null) return;
      final saved = await saveMapEntry(ref, entry);
      if (!saved) {
        messenger.showReplacing(l10n.mapNoProfile);
      }
    }

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sectionText,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionAddToMap,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: addToMap,
                ),
              ],
            ),
            SelectableText(
              text.isEmpty ? '""' : '"$text"',
              key: const Key('interpretation.text'),
              style: theme.textTheme.bodyLarge!.mono,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text(l10n.textSwapBytes),
                  selected: settings.textSwapBytes,
                  onSelected: (v) => controller.setTextSwapBytes(swap: v),
                ),
                SegmentedButton<TextEncoding>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TextEncoding.ascii,
                      label: Text('ASCII'),
                    ),
                    ButtonSegment(
                      value: TextEncoding.latin1,
                      label: Text('Latin-1'),
                    ),
                    ButtonSegment(
                      value: TextEncoding.utf8,
                      label: Text('UTF-8'),
                    ),
                  ],
                  selected: {settings.textEncoding},
                  onSelectionChanged: (s) =>
                      controller.setTextEncoding(s.single),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the interpretation as a draggable bottom sheet (phones).
Future<void> showInterpretationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 1,
        builder: (context, controller) =>
            InterpretationPanel(scrollController: controller),
      ),
    );
