import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/registers/domain/value_input.dart';
import 'package:modbus_explorer/features/registers/presentation/write_description.dart';

void main() {
  group('parseRegisterValue', () {
    final valid = {
      '0': 0,
      '65535': 0xFFFF,
      '-1': 0xFFFF,
      '-32768': 0x8000,
      '0x1A2b': 0x1A2B,
      '0X10': 16,
      '0b1010': 10,
      '0b1111_0000': 0xF0,
      ' 42 ': 42,
    };
    for (final MapEntry(key: input, value: expected) in valid.entries) {
      test('"$input" → $expected', () {
        expect(parseRegisterValue(input), expected);
      });
    }

    for (final input in [
      '',
      '65536',
      '-32769',
      '0x10000',
      '0b2',
      'abc',
      '1.5',
    ]) {
      test('rejects "$input"', () => expect(parseRegisterValue(input), isNull));
    }
  });

  group('lists', () {
    test('register list with mixed separators and formats', () {
      expect(parseRegisterList('1, 0x10;0b11  -1'), [1, 16, 3, 0xFFFF]);
      expect(parseRegisterList('1, x'), isNull);
      expect(parseRegisterList('  '), isNull);
    });

    test('coil list accepts 1/0, on/off and German words', () {
      expect(parseCoilList('1 0 on off ein aus TRUE'), [
        true,
        false,
        true,
        false,
        true,
        false,
        true,
      ]);
      expect(parseCoilList('1 2'), isNull);
    });
  });

  group('describeWrite', () {
    const one = AddressingMode.oneBased;
    test('single register in Modicon notation', () {
      expect(
        describeWrite(WriteSingleRegisterRequest(address: 0, value: 42), one),
        'FC06 · 40001 = 0x002A (42)',
      );
    });

    test('zero-based multiple registers', () {
      expect(
        describeWrite(
          WriteMultipleRegistersRequest(address: 10, values: const [1, 2]),
          AddressingMode.zeroBased,
        ),
        'FC10 · 10…11 = 0x0001, 0x0002',
      );
    });

    test('coils and abbreviation of long lists', () {
      expect(
        describeWrite(WriteSingleCoilRequest(address: 4, value: true), one),
        'FC05 · 00005 = ON',
      );
      final text = describeWrite(
        WriteMultipleCoilsRequest(address: 0, values: List.filled(10, true)),
        one,
      );
      expect(text, endsWith('… (10)'));
    });
  });
}
