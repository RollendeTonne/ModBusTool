import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/tools/domain/hex_input.dart';

void main() {
  group('bytes mode', () {
    final cases = {
      '41 20 00 00': [0x41, 0x20, 0, 0],
      '0x41200000': [0x41, 0x20, 0, 0],
      '41:20:0:0': [0x41, 0x20, 0, 0],
      '41-20,00;00': [0x41, 0x20, 0, 0],
      'a b': [0x0A, 0x0B],
      '  ': <int>[],
    };
    for (final MapEntry(key: input, value: bytes) in cases.entries) {
      test('"$input"', () {
        final result = parseHexInput(input, HexInputMode.bytes);
        expect(result.isValid, isTrue);
        expect(result.bytes, bytes);
      });
    }

    test('odd byte count is padded and flagged', () {
      final result = parseHexInput('41 20 01', HexInputMode.bytes);
      expect(result.bytes, [0x41, 0x20, 0x01, 0x00]);
      expect(result.paddedOddByte, isTrue);
      expect(result.registers, [0x4120, 0x0100]);
    });

    test('reports the first invalid token', () {
      expect(parseHexInput('41 zz 00', HexInputMode.bytes).invalidToken, 'zz');
      expect(parseHexInput('412', HexInputMode.bytes).invalidToken, '412');
      expect(parseHexInput('0x', HexInputMode.bytes).isValid, isFalse);
    });
  });

  group('register modes', () {
    test('hex words', () {
      final result = parseHexInput('4120 0 0xFFFF', HexInputMode.registersHex);
      expect(result.registers, [0x4120, 0, 0xFFFF]);
      expect(
        parseHexInput('12345', HexInputMode.registersHex).invalidToken,
        '12345',
      );
    });

    test('decimal words with negatives and hex/binary prefixes', () {
      final result = parseHexInput(
        '16672, 0, -1 0x10 0b11',
        HexInputMode.registersDecimal,
      );
      expect(result.registers, [0x4120, 0, 0xFFFF, 16, 3]);
      expect(
        parseHexInput('70000', HexInputMode.registersDecimal).invalidToken,
        '70000',
      );
    });
  });
}
