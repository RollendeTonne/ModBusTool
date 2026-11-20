import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Result of [parseHexBytes].
@immutable
final class HexBytes {
  const new(this.bytes, {this.invalidToken});

  final Uint8List bytes;

  /// First token that is not hex; `null` if all were valid.
  final String? invalidToken;

  bool get isValid => invalidToken == null;
}

final _separators = RegExp(r'[\s,;:\-]+');
final _hexDigits = RegExp(r'^[0-9a-f]+$');

/// Hex byte stream as people type it: `41 20 00 00`, `0x41200000`,
/// `41:20:00:00`, `0x41,0x20`. One or two digits are one byte; longer
/// even-length tokens are split into pairs. Shared by the Modbus hex
/// calculator and the MQTT publish/converter tools.
HexBytes parseHexBytes(String text) {
  final bytes = <int>[];
  for (final token in text.trim().split(_separators)) {
    if (token.isEmpty) continue;
    var hex = token.toLowerCase();
    if (hex.startsWith('0x')) hex = hex.substring(2);
    if (hex.isEmpty ||
        !_hexDigits.hasMatch(hex) ||
        (hex.length > 2 && hex.length.isOdd)) {
      return HexBytes(Uint8List(0), invalidToken: token);
    }
    if (hex.length <= 2) {
      bytes.add(int.parse(hex, radix: 16));
    } else {
      for (var i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
    }
  }
  return HexBytes(Uint8List.fromList(bytes));
}
