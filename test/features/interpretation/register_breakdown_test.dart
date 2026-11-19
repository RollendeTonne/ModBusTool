import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_breakdown.dart';

void main() {
  group('RegisterBreakdown', () {
    test('signed/unsigned and bytes of 0xFF80', () {
      final r = RegisterBreakdown(0xFF80);
      expect(r.unsigned, 65408);
      expect(r.signed, -128);
      expect(r.highByte, 0xFF);
      expect(r.highByteSigned, -1);
      expect(r.lowByte, 0x80);
      expect(r.lowByteSigned, -128);
      expect(r.hex, '0xFF80');
      expect(r.binary, '1111 1111 1000 0000');
    });

    test('bits are LSB first', () {
      final r = RegisterBreakdown(0x8001);
      expect(r.bits.first, isTrue);
      expect(r.bits.last, isTrue);
      expect(r.bits.where((b) => b), hasLength(2));
      expect(r.bit(15), isTrue);
      expect(r.bit(1), isFalse);
    });

    test('withBit sets and clears', () {
      expect(RegisterBreakdown(0).withBit(3, value: true), 0x0008);
      expect(RegisterBreakdown(0xFFFF).withBit(15, value: false), 0x7FFF);
      expect(() => RegisterBreakdown(0).bit(16), throwsRangeError);
    });

    test('ascii pair', () {
      expect(RegisterBreakdown(0x4142).ascii, 'AB');
      expect(RegisterBreakdown(0x0041).ascii, '·A');
    });

    test('rejects values outside 16 bit', () {
      expect(() => RegisterBreakdown(0x10000), throwsRangeError);
      expect(() => RegisterBreakdown(-1), throwsRangeError);
    });
  });
}
