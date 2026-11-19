import 'dart:typed_data';

/// `hex('01 03 00 6B')` → bytes. Whitespace is ignored.
Uint8List hex(String text) {
  final clean = text.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16),
  ]);
}
