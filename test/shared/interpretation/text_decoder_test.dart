import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';

void main() {
  group('decodeText', () {
    test('ASCII with NUL padding stripped', () {
      final value = decodeText(registersToBytes([0x4142, 0x4344, 0x0000]));
      expect(value.text, 'ABCD');
      expect(value.hasNonPrintable, isFalse);
    });

    test('byte-swapped registers', () {
      final value = decodeText(
        registersToBytes([0x4241, 0x0043]),
        swapBytes: true,
      );
      expect(value.text, 'ABC');
    });

    test('control characters are flagged', () {
      expect(decodeText([0x41, 0x01]).hasNonPrintable, isTrue);
    });

    test('non-ASCII bytes are flagged in ASCII mode', () {
      final value = decodeText([0x41, 0xC4]);
      expect(value.hasNonPrintable, isTrue);
      expect(value.text, 'A�');
    });

    test('Latin-1 and UTF-8', () {
      expect(decodeText([0xC4], encoding: TextEncoding.latin1).text, 'Ä');
      final utf8Value = decodeText([0xC3, 0x84], encoding: TextEncoding.utf8);
      expect(utf8Value.text, 'Ä');
      expect(utf8Value.hasNonPrintable, isFalse);
      expect(
        decodeText([0xC3], encoding: TextEncoding.utf8).hasNonPrintable,
        isTrue,
      );
    });

    test('all-zero input is empty text', () {
      expect(decodeText([0, 0, 0, 0]).text, isEmpty);
    });
  });
}
