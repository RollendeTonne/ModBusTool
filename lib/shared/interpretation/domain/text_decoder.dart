import 'dart:convert';

import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';

enum TextEncoding { ascii, latin1, utf8 }

/// Decodes a register range as text.
///
/// [swapBytes] swaps the two bytes of each register (BA order), which many
/// devices use for strings. Trailing NUL padding is stripped.
TextValue decodeText(
  List<int> wireBytes, {
  bool swapBytes = false,
  TextEncoding encoding = TextEncoding.ascii,
}) {
  final bytes = [...wireBytes];
  if (swapBytes) {
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final high = bytes[i];
      bytes[i] = bytes[i + 1];
      bytes[i + 1] = high;
    }
  }
  var end = bytes.length;
  while (end > 0 && bytes[end - 1] == 0) {
    end--;
  }
  final trimmed = bytes.sublist(0, end);

  var unrepresentable = false;
  final String text;
  switch (encoding) {
    case TextEncoding.ascii:
      unrepresentable = trimmed.any((b) => b > 0x7F);
      text = String.fromCharCodes(trimmed.map((b) => b > 0x7F ? 0xFFFD : b));
    case TextEncoding.latin1:
      text = latin1.decode(trimmed);
    case TextEncoding.utf8:
      text = utf8.decode(trimmed, allowMalformed: true);
      unrepresentable = text.contains('�');
  }
  return TextValue(
    text,
    hasNonPrintable: unrepresentable || text.runes.any(isControlCharacter),
  );
}

bool isControlCharacter(int rune) =>
    rune < 0x20 || rune == 0x7F || (rune >= 0x80 && rune < 0xA0);
