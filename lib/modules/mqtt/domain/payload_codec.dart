import 'dart:convert';
import 'dart:typed_data';

/// How the user typed a payload.
enum PayloadFormat { text, json, hex, base64 }

/// Encodes [input] in [format] to bytes; throws [FormatException] with a
/// readable message on invalid input.
Uint8List encodePayload(String input, PayloadFormat format) {
  switch (format) {
    case PayloadFormat.text:
      return Uint8List.fromList(utf8.encode(input));
    case PayloadFormat.json:
      if (input.trim().isEmpty) return Uint8List(0);
      // Validates; the text is sent as typed (keeps the user's formatting).
      jsonDecode(input);
      return Uint8List.fromList(utf8.encode(input));
    case PayloadFormat.hex:
      final digits = input.replaceAll(
        RegExp(r'0x|[\s,:;-]', caseSensitive: false),
        '',
      );
      if (digits.length.isOdd) {
        throw const FormatException('Odd number of hex digits');
      }
      if (!RegExp(r'^[0-9a-fA-F]*$').hasMatch(digits)) {
        throw const FormatException('Only 0-9 and A-F allowed');
      }
      return Uint8List.fromList([
        for (var i = 0; i < digits.length; i += 2)
          int.parse(digits.substring(i, i + 2), radix: 16),
      ]);
    case PayloadFormat.base64:
      final cleaned = input.replaceAll(RegExp(r'\s'), '');
      return base64.decode(base64.normalize(cleaned));
  }
}

/// Bytes as `0A 1B …`.
String formatHexBytes(Iterable<int> bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');

/// Short single-line preview of a payload for lists.
String payloadPreview(Uint8List payload, {int maxChars = 120}) {
  if (payload.isEmpty) return '';
  String text;
  try {
    text = utf8.decode(payload);
    // Control characters other than whitespace suggest binary data.
    if (RegExp('[\u0000-\u0008\u000E-\u001F]').hasMatch(text)) {
      text = formatHexBytes(payload.take(maxChars ~/ 3));
    }
  } on FormatException {
    text = formatHexBytes(payload.take(maxChars ~/ 3));
  }
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  return text.length > maxChars ? '${text.substring(0, maxChars)}…' : text;
}
