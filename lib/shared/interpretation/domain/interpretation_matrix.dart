import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/plausibility.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';

@immutable
final class MatrixCell {
  const new({
    required this.order,
    required this.orderedBytes,
    required this.value,
    required this.plausibility,
    required this.isDuplicate,
  });

  final ByteOrder order;

  /// Value bytes after reordering, most significant first (for hex tooltip).
  final Uint8List orderedBytes;
  final InterpretedValue value;
  final PlausibilityAssessment plausibility;

  /// Same byte pattern as an earlier column (e.g. ABCD and CDAB coincide for
  /// 16-bit types); the UI can de-emphasise it.
  final bool isDuplicate;
}

@immutable
final class MatrixRow {
  const new(this.type, this.cells);

  final DataType type;

  /// One entry per [InterpretationMatrix.columns]; `null` if the selection
  /// has fewer registers than the type needs.
  final List<MatrixCell?> cells;
}

/// Data type × byte order interpretation of a register selection, starting
/// at its first register.
@immutable
final class InterpretationMatrix {
  const new _(this.registers, this.rows);

  factory compute(List<int> registers, {List<DataType> types = defaultTypes}) {
    final bytes = registersToBytes(registers);
    final rows = [
      for (final type in types) MatrixRow(type, _cellsFor(bytes, type)),
    ];
    return InterpretationMatrix._(List.unmodifiable(registers), rows);
  }

  static const List<ByteOrderFamily> columns = ByteOrderFamily.values;

  static const List<DataType> defaultTypes = [
    DataType.int16,
    DataType.uint16,
    DataType.int32,
    DataType.uint32,
    DataType.float32,
    DataType.int64,
    DataType.uint64,
    DataType.float64,
    DataType.bcd16,
    DataType.bcd32,
    DataType.unixTime32,
    DataType.unixTime64Ms,
  ];

  final List<int> registers;
  final List<MatrixRow> rows;

  static List<MatrixCell?> _cellsFor(Uint8List bytes, DataType type) {
    final seenPatterns = <String>{};
    return [
      for (final family in columns)
        _cell(bytes, type, ByteOrder.of(family, type.byteWidth), seenPatterns),
    ];
  }

  static MatrixCell? _cell(
    Uint8List bytes,
    DataType type,
    ByteOrder order,
    Set<String> seenPatterns,
  ) {
    final isDuplicate = !seenPatterns.add(order.pattern);
    if (bytes.length < type.byteWidth) return null;
    final ordered = order.arrange(bytes);
    final value = decodeOrderedBytes(ordered, type);
    return MatrixCell(
      order: order,
      orderedBytes: ordered,
      value: value,
      plausibility: assessPlausibility(value, type),
      isDuplicate: isDuplicate,
    );
  }
}
