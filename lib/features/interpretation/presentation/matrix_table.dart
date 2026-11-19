import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/interpretation/presentation/plausibility_text.dart';

enum MatrixCellAction { copy, addToMap }

typedef MatrixCellCallback = void Function(
  MatrixRow row,
  MatrixCell cell,
  MatrixCellAction action,
);

/// Data types (rows) × byte orders (columns). Tap copies a value; the
/// context menu (long press / right click) offers "add to register map".
class InterpretationMatrixTable extends StatelessWidget {
  const new({
    required this.matrix,
    required this.onCellAction,
    this.scaling = Scaling.identity,
    this.highlightPlausible = true,
    super.key,
  });

  final InterpretationMatrix matrix;
  final Scaling scaling;
  final bool highlightPlausible;
  final MatrixCellCallback onCellAction;

  static const _typeWidth = 104.0;
  static const _cellWidth = 156.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        key: const Key('matrix.table'),
        defaultColumnWidth: const FixedColumnWidth(_cellWidth),
        columnWidths: const {0: FixedColumnWidth(_typeWidth)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        children: [
          TableRow(
            children: [
              _HeaderCell(l10n.columnType, style: headerStyle),
              for (final family in InterpretationMatrix.columns)
                _HeaderCell(family.name.toUpperCase(), style: headerStyle.mono),
            ],
          ),
          for (final row in matrix.rows)
            TableRow(
              children: [
                _HeaderCell(row.type.technicalName, style: headerStyle.mono),
                for (final (i, cell) in row.cells.indexed)
                  _cell(row, InterpretationMatrix.columns[i], cell),
              ],
            ),
        ],
      ),
    );
  }
}

extension on InterpretationMatrixTable {
  Widget _cell(MatrixRow row, ByteOrderFamily column, MatrixCell? cell) {
    if (cell == null) return _EmptyCell(registers: row.type.registerCount);
    return _ValueCell(
      // Family, not pattern: 16-bit columns repeat AB/BA.
      key: Key('matrix.${row.type.name}.${column.name}'),
      cell: cell,
      text: ValueFormatter.format(cell.value, scaling: scaling),
      highlightPlausible: highlightPlausible,
      onAction: (action) => onCellAction(row, cell, action),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const new(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Text(text, style: style),
  );
}

class _EmptyCell extends StatelessWidget {
  const new({required this.registers});

  final int registers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: context.l10n.matrixNeedsRegisters(registers),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          ValueFormatter.invalidPlaceholder,
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const new({
    required this.cell,
    required this.text,
    required this.highlightPlausible,
    required this.onAction,
    super.key,
  });

  final MatrixCell cell;
  final String text;
  final bool highlightPlausible;
  final ValueChanged<MatrixCellAction> onAction;

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<MatrixCellAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: MatrixCellAction.copy,
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: Text(l10n.actionCopy),
          ),
        ),
        PopupMenuItem(
          value: MatrixCellAction.addToMap,
          child: ListTile(
            leading: const Icon(Icons.bookmark_add_outlined),
            title: Text(l10n.actionAddToMap),
          ),
        ),
      ],
    );
    if (action != null) onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final level = cell.plausibility.level;
    final isPlausible = highlightPlausible && level == Plausibility.plausible;
    final isImplausible = level == Plausibility.implausible;

    final style = theme.textTheme.bodyMedium!.mono.copyWith(
      color: isImplausible
          ? colors.implausible
          : isPlausible
          ? colors.plausible
          : null,
      fontStyle: isImplausible ? FontStyle.italic : null,
      fontWeight: isPlausible ? FontWeight.w700 : null,
    );
    final reason = plausibilityText(l10n, cell.plausibility);
    final tooltip = [
      '${cell.order.pattern} · ${formatHexBytes(cell.orderedBytes)}',
      ?reason,
      if (cell.isDuplicate) l10n.matrixDuplicate,
    ].join('\n');

    Widget content = Container(
      color: isPlausible ? colors.plausible.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (cell.isDuplicate) content = Opacity(opacity: 0.45, child: content);

    return Semantics(
      button: true,
      label: '${cell.order.pattern}: $text${reason == null ? '' : ', $reason'}',
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () => onAction(MatrixCellAction.copy),
          onLongPress: () {
            final box = context.findRenderObject()! as RenderBox;
            unawaited(
              _showMenu(
                context,
                box.localToGlobal(box.size.center(Offset.zero)),
              ),
            );
          },
          onSecondaryTapUp: (details) =>
              unawaited(_showMenu(context, details.globalPosition)),
          child: content,
        ),
      ),
    );
  }
}
