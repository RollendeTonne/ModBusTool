import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';

void main() {
  test('text is UTF-8', () {
    expect(encodePayload('Ü€', PayloadFormat.text), [
      0xC3,
      0x9C,
      0xE2,
      0x82,
      0xAC,
    ]);
  });

  test('JSON is validated but sent as typed', () {
    expect(encodePayload('{"a": 1}', PayloadFormat.json), '{"a": 1}'.codeUnits);
    expect(encodePayload('  ', PayloadFormat.json), isEmpty);
    expect(
      () => encodePayload('{a:1}', PayloadFormat.json),
      throwsFormatException,
    );
  });

  test('hex accepts common separators', () {
    for (final input in [
      '0A1BFF',
      '0a 1b ff',
      '0x0A,0x1B,0xFF',
      '0A:1B:FF',
      '0a-1b-ff',
    ]) {
      expect(encodePayload(input, PayloadFormat.hex), [
        0x0A,
        0x1B,
        0xFF,
      ], reason: input);
    }
    expect(
      () => encodePayload('ABC', PayloadFormat.hex),
      throwsFormatException,
    );
    expect(() => encodePayload('ZZ', PayloadFormat.hex), throwsFormatException);
  });

  test('base64 tolerates whitespace and missing padding', () {
    expect(encodePayload('SGVs bG8', PayloadFormat.base64), 'Hello'.codeUnits);
    expect(
      () => encodePayload('!!!', PayloadFormat.base64),
      throwsFormatException,
    );
  });

  test('preview shows text or hex for binary', () {
    expect(payloadPreview(Uint8List.fromList('a\nb'.codeUnits)), 'a b');
    expect(payloadPreview(Uint8List.fromList([0, 1, 0xFF])), '00 01 FF');
    expect(
      payloadPreview(Uint8List.fromList(List.filled(200, 0x41)), maxChars: 10),
      'AAAAAAAAAA…',
    );
    expect(payloadPreview(Uint8List(0)), '');
  });
}
