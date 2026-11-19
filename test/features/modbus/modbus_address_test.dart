import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_address.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

void main() {
  const zero = AddressingMode.zeroBased;
  const one = AddressingMode.oneBased;
  const holding = RegisterTable.holdingRegisters;
  const input = RegisterTable.inputRegisters;
  const coils = RegisterTable.coils;

  group('format', () {
    test('zero-based shows the protocol address', () {
      expect(ModbusAddress.format(0, holding, zero), '0');
      expect(ModbusAddress.format(65535, coils, zero), '65535');
    });

    test('one-based uses Modicon notation per table', () {
      expect(ModbusAddress.format(0, holding, one), '40001');
      expect(ModbusAddress.format(0, input, one), '30001');
      expect(
        ModbusAddress.format(0, RegisterTable.discreteInputs, one),
        '10001',
      );
      expect(ModbusAddress.format(0, coils, one), '00001');
      expect(ModbusAddress.format(9998, input, one), '39999');
    });

    test('switches to 6 digits above register 9999', () {
      expect(ModbusAddress.format(9999, holding, one), '410000');
      expect(ModbusAddress.format(65535, holding, one), '465536');
    });

    test('rejects out-of-range protocol addresses', () {
      expect(
        () => ModbusAddress.format(65536, holding, zero),
        throwsRangeError,
      );
      expect(() => ModbusAddress.format(-1, holding, one), throwsRangeError);
    });
  });

  group('parse', () {
    test('zero-based decimal and hex', () {
      expect(ModbusAddress.parse('100', holding, zero), 100);
      expect(ModbusAddress.parse('0x10', holding, zero), 16);
      expect(ModbusAddress.parse(' 0X1f ', holding, zero), 31);
    });

    test('one-based Modicon notation', () {
      expect(ModbusAddress.parse('40001', holding, one), 0);
      expect(ModbusAddress.parse('400001', holding, one), 0);
      expect(ModbusAddress.parse('465536', holding, one), 65535);
      expect(ModbusAddress.parse('30010', input, one), 9);
      expect(ModbusAddress.parse('00001', coils, one), 0);
    });

    test('one-based plain register numbers', () {
      expect(ModbusAddress.parse('1', holding, one), 0);
      expect(ModbusAddress.parse('100', holding, one), 99);
      expect(ModbusAddress.parse('0x10', holding, one), 15);
    });

    test('a prefix of another table is a plain number', () {
      // 40001 on the input-register table means register number 40001.
      expect(ModbusAddress.parse('40001', input, one), 40000);
    });

    for (final (text, mode) in [
      ('', zero),
      ('abc', zero),
      ('-1', zero),
      ('65536', zero),
      ('0', one),
      ('400000', one),
      ('65537', one),
      ('0x', zero),
      ('1.5', zero),
    ]) {
      test('rejects "$text" in $mode', () {
        expect(
          () => ModbusAddress.parse(text, holding, mode),
          throwsA(isA<AddressFormatException>()),
        );
      });
    }

    test('parse(format(a)) round-trips for every table and mode', () {
      const samples = [0, 1, 9, 99, 9998, 9999, 10000, 40000, 65535];
      for (final table in RegisterTable.values) {
        for (final mode in AddressingMode.values) {
          for (final address in samples) {
            final text = ModbusAddress.format(address, table, mode);
            expect(
              ModbusAddress.parse(text, table, mode),
              address,
              reason: '$table $mode "$text"',
            );
          }
        }
      }
    });
  });

  group('checkRange', () {
    test('accepts ranges ending at 65535', () {
      ModbusAddress.checkRange(65535, 1);
      ModbusAddress.checkRange(0, 65536);
    });

    test('rejects overflow and empty ranges', () {
      expect(() => ModbusAddress.checkRange(65535, 2), throwsRangeError);
      expect(() => ModbusAddress.checkRange(0, 0), throwsRangeError);
    });
  });
}
