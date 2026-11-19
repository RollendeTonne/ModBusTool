import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

String float32Text(int high, int low) => ValueFormatter.format(
  decodeValue(
    registersToBytes([high, low]),
    DataType.float32,
    ByteOrder.parse('ABCD'),
  ),
);

void main() {
  group('floats', () {
    test('float32 uses shortest round-trip representation', () {
      expect(float32Text(0x4120, 0x0000), '10.0');
      expect(float32Text(0x4366, 0x199A), '230.1');
      expect(float32Text(0x42F6, 0xE979), '123.456');
      expect(float32Text(0x3DCC, 0xCCCD), '0.1');
      expect(float32Text(0x8000, 0x0000), '-0.0');
    });

    test('special values', () {
      expect(float32Text(0x7FC0, 0), 'NaN');
      expect(float32Text(0x7F80, 0), 'Inf');
      expect(float32Text(0xFF80, 0), '-Inf');
    });

    test('float64 uses Dart shortest representation', () {
      expect(
        ValueFormatter.format(
          const FloatValue(3.141592653589793, precision: FloatPrecision.double),
        ),
        '3.141592653589793',
      );
    });
  });

  group('scaling', () {
    test('factor without decimals hides binary noise', () {
      expect(
        ValueFormatter.format(
          IntegerValue.fromInt(1234),
          scaling: const Scaling(factor: 0.1),
        ),
        '123.4',
      );
    });

    test('fixed decimals and offset', () {
      expect(
        ValueFormatter.format(
          IntegerValue.fromInt(1234),
          scaling: const Scaling(factor: 0.1, decimals: 2),
        ),
        '123.40',
      );
      expect(
        ValueFormatter.format(
          IntegerValue.fromInt(300),
          scaling: const Scaling(factor: 0.5, offset: -40),
        ),
        '110.0',
      );
    });

    test('non-numeric and non-finite values ignore scaling', () {
      const scaling = Scaling(factor: 10);
      expect(
        ValueFormatter.format(
          const InvalidValue(InvalidReason.invalidBcdDigit),
          scaling: scaling,
        ),
        ValueFormatter.invalidPlaceholder,
      );
      expect(
        ValueFormatter.format(
          const FloatValue(double.nan, precision: FloatPrecision.single),
          scaling: scaling,
        ),
        'NaN',
      );
    });

    test('identity check', () {
      expect(Scaling.identity.isIdentity, isTrue);
      expect(const Scaling(decimals: 1).isIdentity, isFalse);
    });
  });

  group('other values', () {
    test('integers and timestamps', () {
      expect(
        ValueFormatter.format(
          IntegerValue(BigInt.parse('18446744073709551615')),
        ),
        '18446744073709551615',
      );
      expect(
        ValueFormatter.format(
          TimestampValue(DateTime.utc(2020, 9, 13, 12, 26, 40)),
        ),
        '2020-09-13 12:26:40Z',
      );
      expect(
        ValueFormatter.formatTimestamp(
          DateTime.utc(2020, 9, 13, 12, 26, 40, 123),
        ),
        '2020-09-13 12:26:40.123Z',
      );
    });

    test('text replaces control characters', () {
      expect(
        ValueFormatter.format(
          const TextValue('A\u0001B', hasNonPrintable: true),
        ),
        'A·B',
      );
    });
  });

  group('hex and binary helpers', () {
    test('formatHex', () {
      expect(formatHex(0x4120), '0x4120');
      expect(formatHex(0xFF, digits: 2, prefix: false), 'FF');
      expect(formatHex(0xA), '0x000A');
    });

    test('formatHexBytes', () {
      expect(formatHexBytes([0x41, 0x20, 0x0, 0xFF]), '41 20 00 FF');
    });

    test('formatBinary groups nibbles', () {
      expect(formatBinary(0x4120), '0100 0001 0010 0000');
      expect(formatBinary(5, bits: 8), '0000 0101');
    });
  });
}
