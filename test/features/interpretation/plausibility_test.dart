import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_decoder.dart';

PlausibilityAssessment assessFloat32(int high, int low) {
  final value = decodeValue(
    registersToBytes([high, low]),
    DataType.float32,
    ByteOrder.parse('ABCD'),
  );
  return assessPlausibility(value, DataType.float32);
}

PlausibilityAssessment assessInt(int value, DataType type) =>
    assessPlausibility(IntegerValue.fromInt(value), type);

void main() {
  group('floats', () {
    test('10.0, 230.1 and 0.1 look plausible', () {
      expect(assessFloat32(0x4120, 0x0000).level, Plausibility.plausible);
      expect(assessFloat32(0x4366, 0x199A).level, Plausibility.plausible);
      expect(assessFloat32(0x3DCC, 0xCCCD).level, Plausibility.plausible);
    });

    test('value with many significant digits is neutral', () {
      // 10.000000953674316 (0x41200001)
      expect(
        assessFloat32(0x4120, 0x0001),
        const PlausibilityAssessment(
          Plausibility.neutral,
          PlausibilityIssue.manyDigits,
        ),
      );
    });

    test('NaN, Inf, denormal, huge and tiny are implausible', () {
      expect(assessFloat32(0x7FC0, 0).issue, PlausibilityIssue.notANumber);
      expect(assessFloat32(0x7F80, 0).issue, PlausibilityIssue.infinite);
      expect(assessFloat32(0, 1).issue, PlausibilityIssue.denormalized);
      // 1.6e-19, a typical byte-swapped float
      expect(assessFloat32(0x2041, 0).issue, PlausibilityIssue.tinyMagnitude);
      // ~1.7e38
      expect(assessFloat32(0x7F00, 0).issue, PlausibilityIssue.hugeMagnitude);
      for (final bits in [(0x7FC0, 0), (0x7F80, 0), (0, 1), (0x2041, 0)]) {
        expect(assessFloat32(bits.$1, bits.$2).level, Plausibility.implausible);
      }
    });

    test('zero is neutral', () {
      expect(assessFloat32(0, 0).level, Plausibility.neutral);
      expect(assessFloat32(0x8000, 0).level, Plausibility.neutral);
    });

    test('float64 short decimals are plausible', () {
      expect(
        assessPlausibility(
          const FloatValue(49.98, precision: FloatPrecision.double),
          DataType.float64,
        ).level,
        Plausibility.plausible,
      );
    });
  });

  group('integers', () {
    test('16-bit values carry no signal', () {
      expect(assessInt(-32768, DataType.int16).level, Plausibility.neutral);
      expect(assessInt(1234, DataType.uint16).level, Plausibility.neutral);
    });

    test('small 32-bit values are plausible, wrapped negatives are not', () {
      expect(assessInt(-5, DataType.int32).level, Plausibility.plausible);
      expect(
        assessInt(4294967291, DataType.uint32).level,
        Plausibility.neutral,
      );
    });

    test('huge 64-bit values are implausible', () {
      expect(
        assessPlausibility(
          IntegerValue(BigInt.parse('18446744073709551615')),
          DataType.uint64,
        ).issue,
        PlausibilityIssue.hugeMagnitude,
      );
    });

    test('valid BCD is neutral (weak evidence)', () {
      expect(assessInt(1234, DataType.bcd16).level, Plausibility.neutral);
      expect(assessInt(41200000, DataType.bcd32).level, Plausibility.neutral);
    });
  });

  group('other values', () {
    test('only recent timestamps are plausible', () {
      final now = DateTime.utc(2026, 11, 19);
      Plausibility level(DateTime t) => assessPlausibility(
        TimestampValue(t),
        DataType.unixTime32,
        now: now,
      ).level;
      expect(level(DateTime.utc(2024, 5)), Plausibility.plausible);
      expect(level(DateTime.utc(2028, 6)), Plausibility.plausible);
      // FLOAT32 10.0 (0x41200000) read as UNIX32 → 2004: in range, but old.
      expect(level(DateTime.utc(2004, 8, 16)), Plausibility.neutral);
      expect(level(DateTime.utc(2060)), Plausibility.neutral);
      expect(
        assessPlausibility(
          TimestampValue(DateTime.utc(1970, 1, 1, 0, 0, 5)),
          DataType.unixTime32,
        ).issue,
        PlausibilityIssue.dateOutOfRange,
      );
      expect(
        assessPlausibility(
          TimestampValue(DateTime.utc(1970)),
          DataType.unixTime32,
        ).level,
        Plausibility.neutral,
      );
    });

    test('invalid values are implausible', () {
      expect(
        assessPlausibility(
          const InvalidValue(InvalidReason.invalidBcdDigit),
          DataType.bcd16,
        ).issue,
        PlausibilityIssue.invalid,
      );
    });

    test('text', () {
      expect(
        assessPlausibility(
          const TextValue('ABC', hasNonPrintable: false),
          DataType.uint16,
        ).level,
        Plausibility.plausible,
      );
      expect(
        assessPlausibility(
          const TextValue('A\u0001', hasNonPrintable: true),
          DataType.uint16,
        ).issue,
        PlausibilityIssue.nonPrintable,
      );
    });
  });
}
