import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/read_plan.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

const RegisterTable holding = RegisterTable.holdingRegisters;
const RegisterTable input = RegisterTable.inputRegisters;
const RegisterTable coils = RegisterTable.coils;

void main() {
  test('merges ranges within the gap, splits beyond it', () {
    final plan = planReads([
      const ReadRange(holding, 0, 2),
      const ReadRange(holding, 5, 2),
      const ReadRange(holding, 30, 1),
    ], maxGap: 4);
    expect(plan, [
      const ReadRange(holding, 0, 7),
      const ReadRange(holding, 30, 1),
    ]);
  });

  test('maxGap 0 only merges adjacent ranges', () {
    final plan = planReads([
      const ReadRange(holding, 0, 2),
      const ReadRange(holding, 2, 2),
      const ReadRange(holding, 5, 1),
    ], maxGap: 0);
    expect(plan, [
      const ReadRange(holding, 0, 4),
      const ReadRange(holding, 5, 1),
    ]);
  });

  test('overlapping and unsorted ranges', () {
    final plan = planReads([
      const ReadRange(holding, 10, 4),
      const ReadRange(holding, 0, 12),
      const ReadRange(holding, 11, 1),
    ]);
    expect(plan, [const ReadRange(holding, 0, 14)]);
  });

  test('respects the 125 register limit', () {
    final plan = planReads([
      const ReadRange(holding, 0, 100),
      const ReadRange(holding, 100, 30),
    ]);
    expect(plan, [
      const ReadRange(holding, 0, 100),
      const ReadRange(holding, 100, 30),
    ]);
  });

  test('bit tables use the 2000 bit limit and tables stay separate', () {
    final plan = planReads([
      const ReadRange(coils, 0, 1500),
      const ReadRange(coils, 1500, 400),
      const ReadRange(input, 0, 1),
      const ReadRange(holding, 0, 1),
    ]);
    expect(plan, [
      const ReadRange(coils, 0, 1900),
      const ReadRange(input, 0, 1),
      const ReadRange(holding, 0, 1),
    ]);
  });

  test('empty input', () => expect(planReads(const []), isEmpty));
}
