import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpretation_matrix.dart';

/// What the interpretation panel shows, derived from the latest read and
/// the selection.
@immutable
final class InterpretationInput {
  const new({
    required this.table,
    required this.start,
    required this.end,
    required this.registers,
    required this.selected,
  });

  final RegisterTable table;

  /// First and last selected protocol address.
  final int start;
  final int end;

  /// From [start]; at least 4 registers when available, so 32/64-bit
  /// types can be shown for a single selected register.
  final List<int> registers;

  /// Exactly the selected registers (used for text).
  final List<int> selected;

  int get selectionLength => end - start + 1;
}

/// Wider types need this many registers starting at the selection.
const _matrixRegisters = 4;

final interpretationInputProvider = Provider<InterpretationInput?>((ref) {
  final state = ref.watch(registersControllerProvider);
  final snapshot = state.snapshot;
  if (snapshot == null || snapshot.table.isBitTable) return null;
  var start = state.selectionStart ?? snapshot.start;
  var end = state.selectionEnd ?? start;
  if (!snapshot.covers(snapshot.table, start)) {
    start = snapshot.start;
    end = start;
  }
  if (end > snapshot.end) end = snapshot.end;
  final offset = start - snapshot.start;
  // Exclusive end index: the selection, but at least 4 registers if the
  // read range has them.
  final selectionEnd = end - snapshot.start + 1;
  final matrixEnd = min(
    max(selectionEnd, offset + _matrixRegisters),
    snapshot.count,
  );
  return InterpretationInput(
    table: snapshot.table,
    start: start,
    end: end,
    registers: snapshot.values.sublist(offset, matrixEnd),
    selected: snapshot.values.sublist(offset, end - snapshot.start + 1),
  );
});

final interpretationMatrixProvider = Provider<InterpretationMatrix?>((ref) {
  final input = ref.watch(interpretationInputProvider);
  return input == null ? null : InterpretationMatrix.compute(input.registers);
});
