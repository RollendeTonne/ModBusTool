import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/registers/domain/value_input.dart';
import 'package:modbus_explorer/shared/interpretation/domain/hex_bytes.dart';

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
  final bytes = <int>[];
  if (mode == HexInputMode.bytes) {
    final parsed = parseHexBytes(text);
    if (!parsed.isValid) {
      return HexInputResult(
        bytes: Uint8List(0),
        invalidToken: parsed.invalidToken,
      );
    }
    bytes.addAll(parsed.bytes);
  }
  final tokens = mode == HexInputMode.bytes
      ? const <String>[]
      : text.trim().split(separators).where((t) => t.isNotEmpty);
  for (final token in tokens) {
    final parsed = _wordToken(token, hex: mode == HexInputMode.registersHex);
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
