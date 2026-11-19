import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_encoder.dart';

void main() {
  group('reference encodings', () {
    test('FLOAT32 10.0 in every family', () {
      const expected = {
        ByteOrderFamily.abcd: [0x41, 0x20, 0x00, 0x00],
        ByteOrderFamily.badc: [0x20, 0x41, 0x00, 0x00],
        ByteOrderFamily.cdab: [0x00, 0x00, 0x41, 0x20],
        ByteOrderFamily.dcba: [0x00, 0x00, 0x20, 0x41],
      };
      for (final MapEntry(key: family, value: bytes) in expected.entries) {
        expect(
          encodeValue(DataType.float32, ByteOrder.of(family, 4), '10'),
          bytes,
          reason: family.name,
        );
      }
    });

    test('integers, hex and negative values', () {
      expect(encodeValue(DataType.int16, ByteOrder.parse('AB'), '-1234'), [
        0xFB,
        0x2E,
      ]);
      expect(encodeValue(DataType.uint16, ByteOrder.parse('BA'), '0x0102'), [
        0x02,
        0x01,
      ]);
      expect(
        encodeValue(
          DataType.uint64,
          ByteOrder.parse('ABCDEFGH'),
          '18446744073709551615',
        ),
        List.filled(8, 0xFF),
      );
    });

    test('BCD, decimal comma and timestamps', () {
      expect(encodeValue(DataType.bcd16, ByteOrder.parse('AB'), '1234'), [
        0x12,
        0x34,
      ]);
      expect(encodeValue(DataType.bcd32, ByteOrder.parse('ABCD'), '56'), [
        0,
        0,
        0,
        0x56,
      ]);
      expect(encodeValue(DataType.float32, ByteOrder.parse('ABCD'), '230,1'), [
        0x43,
        0x66,
        0x19,
        0x9A,
      ]);
      expect(
        encodeValue(
          DataType.unixTime32,
          ByteOrder.parse('ABCD'),
          '2020-09-13T12:26:40Z',
        ),
        [0x5F, 0x5E, 0x10, 0x00],
      );
    });
  });

  group('round trip through the decoder', () {
    const samples = {
      DataType.int16: '-32768',
      DataType.uint16: '65535',
      DataType.int32: '-123456',
      DataType.uint32: '4000000000',
      DataType.int64: '-9223372036854775808',
      DataType.uint64: '1234567890123',
      DataType.float32: '49.98',
      DataType.float64: '3.141592653589793',
      DataType.bcd16: '9876',
      DataType.bcd32: '12345678',
      DataType.unixTime32: '1600000000',
      DataType.unixTime64Ms: '1600000000123',
    };
    for (final MapEntry(key: type, value: input) in samples.entries) {
      for (final family in ByteOrderFamily.values) {
        test('$type ${family.name}', () {
          final order = ByteOrder.of(family, type.byteWidth);
          final decoded = decodeValue(
            encodeValue(type, order, input),
            type,
            order,
          );
          final text = switch (decoded) {
            IntegerValue(:final value) => '$value',
            FloatValue(:final value) => '$value',
            TimestampValue(:final value) =>
              type == DataType.unixTime32
                  ? '${value.millisecondsSinceEpoch ~/ 1000}'
                  : '${value.millisecondsSinceEpoch}',
            _ => '$decoded',
          };
          if (type == DataType.float32) {
            expect(double.parse(text), closeTo(49.98, 1e-5));
          } else {
            expect(text, input);
          }
        });
      }
    }
  });

  group('invalid input', () {
    for (final (type, input) in [
      (DataType.int16, '32768'),
      (DataType.uint16, '-1'),
      (DataType.uint32, 'abc'),
      (DataType.float32, ''),
      (DataType.bcd16, '12345'),
      (DataType.bcd16, '12a4'),
      (DataType.unixTime32, '-5'),
      (DataType.unixTime32, 'yesterday'),
    ]) {
      test('$type rejects "$input"', () {
        expect(
          () => encodeValue(
            type,
            ByteOrder.of(ByteOrderFamily.abcd, type.byteWidth),
            input,
          ),
          throwsFormatException,
        );
      });
    }

    test('mismatched byte order width', () {
      expect(
        () => encodeValue(DataType.float32, ByteOrder.parse('AB'), '1'),
        throwsArgumentError,
      );
    });

    test('special float values', () {
      final nan = encodeValue(DataType.float32, ByteOrder.parse('ABCD'), 'NaN');
      expect(nan[0] & 0x7F, 0x7F);
      expect(encodeValue(DataType.float32, ByteOrder.parse('ABCD'), '-inf'), [
        0xFF,
        0x80,
        0,
        0,
      ]);
    });
  });
}
