import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';

MatrixRow rowOf(InterpretationMatrix matrix, DataType type) =>
    matrix.rows.singleWhere((r) => r.type == type);

void main() {
  group('InterpretationMatrix', () {
    test('has one row per default type and one cell per column', () {
      final matrix = InterpretationMatrix.compute(const [0x4120, 0]);
      expect(matrix.rows.map((r) => r.type), InterpretationMatrix.defaultTypes);
      for (final row in matrix.rows) {
        expect(row.cells, hasLength(ByteOrderFamily.values.length));
      }
    });

    test('FLOAT32 10.0 is found and marked plausible only in ABCD', () {
      final matrix = InterpretationMatrix.compute(const [0x4120, 0x0000]);
      final cells = rowOf(matrix, DataType.float32).cells;
      final abcd = cells[ByteOrderFamily.abcd.index]!;
      expect(abcd.order.pattern, 'ABCD');
      expect((abcd.value as FloatValue).value, 10.0);
      expect(abcd.plausibility.level, Plausibility.plausible);
      expect(abcd.orderedBytes, [0x41, 0x20, 0x00, 0x00]);
      for (final family in [
        ByteOrderFamily.badc,
        ByteOrderFamily.cdab,
        ByteOrderFamily.dcba,
      ]) {
        expect(
          cells[family.index]!.plausibility.level,
          Plausibility.implausible,
        );
      }
    });

    test('types wider than the selection have no cells', () {
      final matrix = InterpretationMatrix.compute(const [0x4120, 0x0000]);
      expect(rowOf(matrix, DataType.float64).cells, everyElement(isNull));
      expect(rowOf(matrix, DataType.int32).cells, everyElement(isNotNull));
    });

    test('16-bit columns repeating an earlier pattern are duplicates', () {
      final matrix = InterpretationMatrix.compute(const [0x4120]);
      final cells = rowOf(matrix, DataType.uint16).cells;
      expect(cells.map((c) => c!.order.pattern), ['AB', 'BA', 'AB', 'BA']);
      expect(cells.map((c) => c!.isDuplicate), [false, false, true, true]);
      expect((cells[0]!.value as IntegerValue).value, BigInt.from(0x4120));
      expect((cells[1]!.value as IntegerValue).value, BigInt.from(0x2041));
    });

    test('64-bit types are filled with four registers', () {
      final matrix = InterpretationMatrix.compute(const [0x4024, 0, 0, 0]);
      final cell = rowOf(matrix, DataType.float64).cells.first!;
      expect((cell.value as FloatValue).value, 10.0);
      expect(cell.isDuplicate, isFalse);
    });

    test('empty selection yields only empty cells', () {
      final matrix = InterpretationMatrix.compute(const []);
      for (final row in matrix.rows) {
        expect(row.cells, everyElement(isNull));
      }
    });

    test('custom type list', () {
      final matrix = InterpretationMatrix.compute(
        const [0x1234],
        types: const [DataType.bcd16],
      );
      expect(matrix.rows, hasLength(1));
      expect(
        (matrix.rows.single.cells.first!.value as IntegerValue).value,
        BigInt.from(1234),
      );
    });
  });
}
