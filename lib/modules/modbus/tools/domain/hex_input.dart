import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/registers/domain/value_input.dart';

enum HexInputMode {
  /// Byte stream, e.g. `41 20 00 00`, `0x41200000`, `41:20:00:00`.
  bytes,

  /// 16-bit words in hex, e.g. `4120 0000`.
  registersHex,

  /// 16-bit words in decimal (negative = two's complement).
  registersDecimal,
}

@immutable
final class HexInputResult {
  const new({
    required this.bytes,
    this.invalidToken,
    this.paddedOddByte = false,
  });

  final Uint8List bytes;

  /// First token that could not be parsed; `null` if all were valid.
  final String? invalidToken;

  /// An odd byte count was padded with 0x00 to form full registers.
  final bool paddedOddByte;

  bool get isValid => invalidToken == null;

  List<int> get registers => [
    for (var i = 0; i < bytes.length; i += 2)
      (bytes[i] << 8) | (i + 1 < bytes.length ? bytes[i + 1] : 0),
  ];
}

final _byteSeparators = RegExp(r'[\s,;:\-]+');

// '-' is a sign in decimal mode, so it cannot separate tokens there.
final _decimalSeparators = RegExp(r'[\s,;]+');

HexInputResult parseHexInput(String text, HexInputMode mode) {
  final separators = mode == HexInputMode.registersDecimal
      ? _decimalSeparators
      : _byteSeparators;
  final tokens = text.trim().split(separators).where((t) => t.isNotEmpty);
  final bytes = <int>[];
  for (final token in tokens) {
    final parsed = switch (mode) {
      HexInputMode.bytes => _byteToken(token),
      HexInputMode.registersHex => _wordToken(token, hex: true),
      HexInputMode.registersDecimal => _wordToken(token, hex: false),
    };
    if (parsed == null) {
      return HexInputResult(bytes: Uint8List(0), invalidToken: token);
    }
    bytes.addAll(parsed);
  }
  final padded = bytes.length.isOdd;
  if (padded) bytes.add(0);
  return HexInputResult(
    bytes: Uint8List.fromList(bytes),
    paddedOddByte: padded,
  );
}

/// One or two hex digits = one byte; longer even-length tokens are split
/// into byte pairs (`41200000` → 41 20 00 00).
List<int>? _byteToken(String token) {
  var hex = token.toLowerCase();
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.isEmpty || !RegExp(r'^[0-9a-f]+$').hasMatch(hex)) return null;
  if (hex.length <= 2) return [int.parse(hex, radix: 16)];
  if (hex.length.isOdd) return null;
  return [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

List<int>? _wordToken(String token, {required bool hex}) {
  final int? value;
  if (hex) {
    var digits = token.toLowerCase();
    if (digits.startsWith('0x')) digits = digits.substring(2);
    value = digits.isEmpty || digits.length > 4
        ? null
        : int.tryParse(digits, radix: 16);
  } else {
    value = parseRegisterValue(token);
  }
  if (value == null) return null;
  return [value >> 8, value & 0xFF];
}
