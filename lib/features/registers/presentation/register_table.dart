import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_breakdown.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_address.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/registers/domain/register_snapshot.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/registers/presentation/write_dialogs.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';

/// How long a changed value stays highlighted.
const changeHighlightDuration = Duration(milliseconds: 1500);

const _rowHeight = 40.0;
const _addressWidth = 120.0;
const _numberWidth = 90.0;
const _binaryWidth = 190.0;

/// Pinned column header plus virtualized rows, as slivers so the whole
/// page (request panel included) scrolls on small screens.
class RegisterTableSliver extends ConsumerWidget {
  const new({required this.snapshot, super.key});

  final RegisterSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.addressingMode),
    );
    final writeUnlocked = ref.watch(
      registersControllerProvider.select((s) => s.writeUnlocked),
    );
    final table = snapshot.table;
    final canWrite = writeUnlocked && table.isWritable;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final showSigned = width >= 480;
        final showBinary = width >= 720;
        return SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                table: table,
                showSigned: showSigned,
                showBinary: showBinary,
              ),
            ),
            SliverFixedExtentList.builder(
              key: const Key('registers.list'),
              itemExtent: _rowHeight,
              itemCount: snapshot.count,
              itemBuilder: (context, i) {
                final address = snapshot.start + i;
                return _RegisterRow(
                  table: table,
                  address: address,
                  displayAddress: ModbusAddress.format(address, table, mode),
                  value: snapshot.values[i],
                  changedAt: snapshot.changedAt[i],
                  showSigned: showSigned,
                  showBinary: showBinary,
                  canWrite: canWrite,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  new({
    required this.table,
    required this.showSigned,
    required this.showBinary,
  });

  static const _height = 36.0;

  final RegisterTable table;
  final bool showSigned;
  final bool showBinary;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.table != table ||
      old.showSigned != showSigned ||
      old.showBinary != showBinary;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return DefaultTextStyle(
      style: theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: _addressWidth, child: Text(l10n.columnAddress)),
            if (table.isBitTable)
              Expanded(child: Text(l10n.columnValue))
            else ...[
              SizedBox(width: _numberWidth, child: Text(l10n.columnHex)),
              SizedBox(width: _numberWidth, child: Text(l10n.columnUnsigned)),
              if (showSigned)
                SizedBox(width: _numberWidth, child: Text(l10n.columnSigned)),
              if (showBinary)
                SizedBox(width: _binaryWidth, child: Text(l10n.columnBinary)),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegisterRow extends ConsumerWidget {
  const new({
    required this.table,
    required this.address,
    required this.displayAddress,
    required this.value,
    required this.changedAt,
    required this.showSigned,
    required this.showBinary,
    required this.canWrite,
  });

  final RegisterTable table;
  final int address;
  final String displayAddress;
  final int value;
  final DateTime? changedAt;
  final bool showSigned;
  final bool showBinary;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final changedColor = context.appColors.changed;

    final Widget content;
    final String semanticValue;
    if (table.isBitTable) {
      final on = value != 0;
      semanticValue = on ? l10n.bitOn : l10n.bitOff;
      content = Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              semanticValue,
              style: mono.copyWith(
                fontWeight: FontWeight.w600,
                color: on
                    ? context.appColors.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (table == RegisterTable.coils)
            Switch(
              key: Key('coil.$address'),
              value: on,
              onChanged: canWrite
                  ? (v) => performWrite(
                      context,
                      ref,
                      WriteSingleCoilRequest(address: address, value: v),
                    )
                  : null,
            ),
        ],
      );
    } else {
      final r = RegisterBreakdown(value);
      semanticValue = '${r.unsigned}';
      content = Row(
        children: [
          SizedBox(
            width: _numberWidth,
            child: SelectableText(r.hex, style: mono),
          ),
          SizedBox(
            width: _numberWidth,
            child: SelectableText('${r.unsigned}', style: mono),
          ),
          if (showSigned)
            SizedBox(
              width: _numberWidth,
              child: SelectableText('${r.signed}', style: mono),
            ),
          if (showBinary)
            SizedBox(
              width: _binaryWidth,
              child: SelectableText(r.binary, style: mono),
            ),
          const Spacer(),
          if (table == RegisterTable.holdingRegisters)
            IconButton(
              key: Key('write.$address'),
              tooltip: l10n.actionWriteRow,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: canWrite ? () => _writeRegister(context, ref) : null,
            ),
        ],
      );
    }

    final row = Semantics(
      label: '${l10n.columnAddress} $displayAddress: $semanticValue',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: _addressWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayAddress,
                    style: mono.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatHex(address),
                    style: theme.textTheme.labelSmall!.mono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );

    return _ChangeHighlight(
      changedAt: changedAt,
      color: changedColor,
      child: row,
    );
  }

  Future<void> _writeRegister(BuildContext context, WidgetRef ref) async {
    final request = await showWriteRegisterDialog(
      context,
      address: address,
      displayAddress: displayAddress,
      currentValue: value,
    );
    if (request != null && context.mounted) {
      await performWrite(context, ref, request);
    }
  }
}

/// Background flash that fades out over [changeHighlightDuration]. Picks up
/// mid-fade when a row scrolls into view shortly after a change.
class _ChangeHighlight extends StatelessWidget {
  const new({
    required this.changedAt,
    required this.color,
    required this.child,
  });

  final DateTime? changedAt;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final changed = changedAt;
    if (changed == null) return child;
    final elapsed = DateTime.now().difference(changed);
    if (elapsed >= changeHighlightDuration) return child;
    final start =
        1 - elapsed.inMilliseconds / changeHighlightDuration.inMilliseconds;
    return TweenAnimationBuilder<double>(
      key: ValueKey(changed),
      tween: Tween(begin: start, end: 0),
      duration: changeHighlightDuration - elapsed,
      builder: (context, t, child) => ColoredBox(
        color: color.withValues(alpha: t),
        child: child,
      ),
      child: child,
    );
  }
}
