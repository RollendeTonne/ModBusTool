import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/modbus/data/codec/crc16.dart';

import '../../helpers/hex.dart';

void main() {
  group('CRC-16/MODBUS', () {
    test('standard check value of "123456789" is 0x4B37', () {
      expect(crc16Modbus('123456789'.codeUnits), 0x4B37);
    });

    test('spec example 11 03 00 6B 00 03 → 76 87', () {
      expect(
        appendCrc(hex('11 03 00 6B 00 03')),
        hex('11 03 00 6B 00 03 76 87'),
      );
    });

    test('read 10 holding registers from slave 1 → C5 CD', () {
      expect(
        appendCrc(hex('01 03 00 00 00 0A')),
        hex('01 03 00 00 00 0A C5 CD'),
      );
    });

    test('empty input yields the init value', () {
      expect(crc16Modbus(const []), 0xFFFF);
    });

    test('sub-range calculation', () {
      final bytes = hex('FF 11 03 00 6B 00 03 FF');
      expect(crc16Modbus(bytes, 1, 7), 0x8776);
    });

    test('validation detects single-bit errors', () {
      final frame = hex('11 03 00 6B 00 03 76 87');
      expect(hasValidCrc(frame), isTrue);
      for (var i = 0; i < frame.length; i++) {
        final broken = [...frame];
        broken[i] ^= 0x01;
        expect(hasValidCrc(broken), isFalse, reason: 'bit flip at byte $i');
      }
      expect(hasValidCrc(hex('11 03')), isFalse);
    });
  });
}
