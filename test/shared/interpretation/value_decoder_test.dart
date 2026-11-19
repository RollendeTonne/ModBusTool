import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';

InterpretedValue decodeRegisters(
  List<int> registers,
  DataType type,
  String order,
) => decodeValue(registersToBytes(registers), type, ByteOrder.parse(order));

double floatOf(InterpretedValue v) => (v as FloatValue).value;
BigInt intOf(InterpretedValue v) => (v as IntegerValue).value;

void main() {
  group('FLOAT32 10.0 (0x41200000) in every byte order', () {
    const cases = {
      'ABCD': [0x4120, 0x0000],
      'BADC': [0x2041, 0x0000],
      'CDAB': [0x0000, 0x4120],
      'DCBA': [0x0000, 0x2041],
    };
    for (final MapEntry(key: order, value: registers) in cases.entries) {
      test('$order from $registers', () {
        expect(
          floatOf(decodeRegisters(registers, DataType.float32, order)),
          10.0,
        );
      });
    }

    test('wrong orders of ABCD-encoded 10.0 give the reference garbage', () {
      const registers = [0x4120, 0x0000];
      expect(
        floatOf(decodeRegisters(registers, DataType.float32, 'BADC')),
        closeTo(1.6347735882007997e-19, 1e-30),
      );
      final cdab = decodeRegisters(registers, DataType.float32, 'CDAB');
      expect(floatOf(cdab), closeTo(2.336244799722335e-41, 1e-50));
      expect((cdab as FloatValue).isDenormal, isTrue);
    });
  });

  group('FLOAT32 references', () {
    test('123.456 = 0x42F6E979', () {
      expect(
        floatOf(decodeRegisters([0x42F6, 0xE979], DataType.float32, 'ABCD')),
        closeTo(123.456, 1e-5),
      );
    });

    test('special values', () {
      expect(
        floatOf(decodeRegisters([0x7FC0, 0], DataType.float32, 'ABCD')).isNaN,
        isTrue,
      );
      expect(
        floatOf(decodeRegisters([0x7F80, 0], DataType.float32, 'ABCD')),
        double.infinity,
      );
      expect(
        floatOf(decodeRegisters([0xFF80, 0], DataType.float32, 'ABCD')),
        double.negativeInfinity,
      );
      final negativeZero = floatOf(
        decodeRegisters([0x8000, 0], DataType.float32, 'ABCD'),
      );
      expect(negativeZero, 0);
      expect(negativeZero.isNegative, isTrue);
    });

    test('denormal detection uses raw bits', () {
      final denormal = decodeRegisters([0, 1], DataType.float32, 'ABCD');
      expect((denormal as FloatValue).isDenormal, isTrue);
      final normal = decodeRegisters([0x0080, 0], DataType.float32, 'ABCD');
      expect((normal as FloatValue).isDenormal, isFalse);
      final zero = decodeRegisters([0, 0], DataType.float32, 'ABCD');
      expect((zero as FloatValue).isDenormal, isFalse);
    });
  });

  group('FLOAT64', () {
    const cases = {
      'ABCDEFGH': [0x4024, 0, 0, 0],
      'BADCFEHG': [0x2440, 0, 0, 0],
      'GHEFCDAB': [0, 0, 0, 0x4024],
      'HGFEDCBA': [0, 0, 0, 0x2440],
    };
    for (final MapEntry(key: order, value: registers) in cases.entries) {
      test('10.0 in $order', () {
        expect(
          floatOf(decodeRegisters(registers, DataType.float64, order)),
          10.0,
        );
      });
    }

    test('pi = 0x400921FB54442D18', () {
      expect(
        floatOf(
          decodeRegisters(
            [0x4009, 0x21FB, 0x5444, 0x2D18],
            DataType.float64,
            'ABCDEFGH',
          ),
        ),
        3.141592653589793,
      );
    });

    test('smallest denormal', () {
      final value = decodeRegisters([0, 0, 0, 1], DataType.float64, 'ABCDEFGH');
      expect(floatOf(value), 5e-324);
      expect((value as FloatValue).isDenormal, isTrue);
    });
  });

  group('16-bit integers', () {
    test('INT16 / UINT16 of 0x8000', () {
      expect(
        intOf(decodeRegisters([0x8000], DataType.int16, 'AB')),
        BigInt.from(-32768),
      );
      expect(
        intOf(decodeRegisters([0x8000], DataType.uint16, 'AB')),
        BigInt.from(32768),
      );
    });

    test('BA swaps bytes', () {
      expect(
        intOf(decodeRegisters([0x0102], DataType.uint16, 'BA')),
        BigInt.from(0x0201),
      );
      expect(
        intOf(decodeRegisters([0xFF7F], DataType.int16, 'BA')),
        BigInt.from(0x7FFF),
      );
    });
  });

  group('32-bit integers', () {
    test('0xDEADBEEF', () {
      const registers = [0xDEAD, 0xBEEF];
      expect(
        intOf(decodeRegisters(registers, DataType.uint32, 'ABCD')),
        BigInt.from(3735928559),
      );
      expect(
        intOf(decodeRegisters(registers, DataType.int32, 'ABCD')),
        BigInt.from(-559038737),
      );
    });

    test('0x12345678 in all orders', () {
      const registers = [0x1234, 0x5678];
      expect(
        intOf(decodeRegisters(registers, DataType.uint32, 'ABCD')),
        BigInt.from(0x12345678),
      );
      expect(
        intOf(decodeRegisters(registers, DataType.uint32, 'CDAB')),
        BigInt.from(0x56781234),
      );
      expect(
        intOf(decodeRegisters(registers, DataType.uint32, 'BADC')),
        BigInt.from(0x34127856),
      );
      expect(
        intOf(decodeRegisters(registers, DataType.uint32, 'DCBA')),
        BigInt.from(0x78563412),
      );
    });

    test('-1 and boundaries', () {
      expect(
        intOf(decodeRegisters([0xFFFF, 0xFFFF], DataType.int32, 'ABCD')),
        BigInt.from(-1),
      );
      expect(
        intOf(decodeRegisters([0x8000, 0], DataType.int32, 'ABCD')),
        BigInt.from(-2147483648),
      );
      expect(
        intOf(decodeRegisters([0xFFFF, 0xFFFF], DataType.uint32, 'ABCD')),
        BigInt.from(4294967295),
      );
    });
  });

  group('64-bit integers', () {
    // Reference values computed independently with Python's int(hex, 16).
    final bytes = [1, 2, 3, 4, 5, 6, 7, 8];
    final cases = {
      'ABCDEFGH': BigInt.parse('72623859790382856'),
      'BADCFEHG': BigInt.parse('144401074084972551'),
      'GHEFCDAB': BigInt.parse('506660481457717506'),
      'HGFEDCBA': BigInt.parse('578437695752307201'),
      'EFGHABCD': BigInt.parse('361984551007945476'),
      'CDABGHEF': BigInt.parse('217299790240154886'),
    };
    for (final MapEntry(key: order, value: expected) in cases.entries) {
      test('bytes 01..08 as $order', () {
        expect(
          intOf(decodeValue(bytes, DataType.uint64, ByteOrder.parse(order))),
          expected,
        );
      });
    }

    test('UINT64 max stays exact, INT64 is -1', () {
      const allOnes = [0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF];
      expect(
        intOf(decodeRegisters(allOnes, DataType.uint64, 'ABCDEFGH')),
        BigInt.parse('18446744073709551615'),
      );
      expect(
        intOf(decodeRegisters(allOnes, DataType.int64, 'ABCDEFGH')),
        BigInt.from(-1),
      );
    });

    test('INT64 min and max', () {
      expect(
        intOf(decodeRegisters([0x8000, 0, 0, 0], DataType.int64, 'ABCDEFGH')),
        BigInt.parse('-9223372036854775808'),
      );
      expect(
        intOf(
          decodeRegisters(
            [0x7FFF, 0xFFFF, 0xFFFF, 0xFFFF],
            DataType.int64,
            'ABCDEFGH',
          ),
        ),
        BigInt.parse('9223372036854775807'),
      );
    });
  });

  group('BCD', () {
    test('BCD16 0x1234 = 1234, BA of 0x3412 = 1234', () {
      expect(
        intOf(decodeRegisters([0x1234], DataType.bcd16, 'AB')),
        BigInt.from(1234),
      );
      expect(
        intOf(decodeRegisters([0x3412], DataType.bcd16, 'BA')),
        BigInt.from(1234),
      );
    });

    test('BCD32 in ABCD and CDAB', () {
      expect(
        intOf(decodeRegisters([0x0012, 0x3456], DataType.bcd32, 'ABCD')),
        BigInt.from(123456),
      );
      expect(
        intOf(decodeRegisters([0x3456, 0x0012], DataType.bcd32, 'CDAB')),
        BigInt.from(123456),
      );
    });

    test('nibble above 9 is invalid', () {
      expect(
        decodeRegisters([0x12A4], DataType.bcd16, 'AB'),
        const InvalidValue(InvalidReason.invalidBcdDigit),
      );
    });
  });

  group('Unix timestamps', () {
    test('UNIX32 1600000000 = 2020-09-13 12:26:40 UTC', () {
      final value = decodeRegisters(
        [0x5F5E, 0x1000],
        DataType.unixTime32,
        'ABCD',
      );
      expect(
        (value as TimestampValue).value,
        DateTime.utc(2020, 9, 13, 12, 26, 40),
      );
    });

    test('UNIX64 ms 1600000000123 (0x174876E807B)', () {
      final value = decodeRegisters(
        [0x0000, 0x0174, 0x876E, 0x807B],
        DataType.unixTime64Ms,
        'ABCDEFGH',
      );
      expect(
        (value as TimestampValue).value,
        DateTime.utc(2020, 9, 13, 12, 26, 40, 123),
      );
    });

    test('UNIX64 beyond DateTime range is invalid', () {
      expect(
        decodeRegisters(
          [0x7FFF, 0xFFFF, 0xFFFF, 0xFFFF],
          DataType.unixTime64Ms,
          'ABCDEFGH',
        ),
        const InvalidValue(InvalidReason.timestampOutOfRange),
      );
    });
  });

  group('input validation', () {
    test('insufficient bytes yield InvalidValue', () {
      expect(
        decodeRegisters([0x4120], DataType.float32, 'ABCD'),
        const InvalidValue(InvalidReason.insufficientData),
      );
    });

    test('offset selects the starting register', () {
      expect(
        floatOf(
          decodeValue(
            registersToBytes([0xFFFF, 0x4120, 0x0000]),
            DataType.float32,
            ByteOrder.parse('ABCD'),
            offset: 2,
          ),
        ),
        10.0,
      );
    });

    test('order width must match type width', () {
      expect(
        () => decodeRegisters([1, 2], DataType.float32, 'AB'),
        throwsArgumentError,
      );
    });
  });
}
