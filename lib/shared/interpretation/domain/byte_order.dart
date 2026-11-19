import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The four common register/byte arrangements, expressed as two independent
/// swaps so one definition covers 16-, 32- and 64-bit values.
enum ByteOrderFamily {
  /// Big endian: registers and bytes in wire order (ABCD).
  abcd(swapWords: false, swapBytes: false),

  /// Bytes swapped within each register (BADC).
  badc(swapWords: false, swapBytes: true),

  /// Register order reversed, bytes within a register kept (CDAB).
  cdab(swapWords: true, swapBytes: false),

  /// Little endian: everything reversed (DCBA).
  dcba(swapWords: true, swapBytes: true);

  new({required this.swapWords, required this.swapBytes});

  final bool swapWords;
  final bool swapBytes;
}

/// Maps wire bytes to the value's bytes, most significant first.
///
/// Letters name wire positions: `A` is the high byte of the first register.
/// The pattern lists which wire byte ends up at each position of the value,
/// e.g. `CDAB` means the value is `C D A B` read as big endian.
@immutable
final class ByteOrder {
  const new _(this.pattern, this.permutation);

  factory parse(String pattern) {
    final normalized = pattern.trim().toUpperCase();
    final width = normalized.length;
    if (!supportedWidths.contains(width)) {
      throw FormatException('Byte order must have 2, 4 or 8 letters', pattern);
    }
    final permutation = <int>[];
    for (final unit in normalized.codeUnits) {
      final index = unit - _letterA;
      if (index < 0 || index >= width) {
        throw FormatException(
          'Byte order may only use letters A..${_letter(width - 1)}',
          pattern,
        );
      }
      if (permutation.contains(index)) {
        throw FormatException('Byte order repeats a letter', pattern);
      }
      permutation.add(index);
    }
    return ByteOrder._(normalized, List.unmodifiable(permutation));
  }

  factory of(ByteOrderFamily family, int width) {
    if (!supportedWidths.contains(width)) {
      throw ArgumentError.value(width, 'width', 'must be 2, 4 or 8');
    }
    final registerCount = width ~/ 2;
    final permutation = <int>[];
    for (var i = 0; i < registerCount; i++) {
      final register = family.swapWords ? registerCount - 1 - i : i;
      final high = register * 2;
      final low = high + 1;
      permutation.addAll(family.swapBytes ? [low, high] : [high, low]);
    }
    return ByteOrder._(
      permutation.map(_letter).join(),
      List.unmodifiable(permutation),
    );
  }

  static const supportedWidths = {2, 4, 8};
  static const _letterA = 0x41;

  /// Less common 64-bit layouts seen in the field (32-bit halves swapped,
  /// or words swapped inside each half). Offered in addition to the families.
  static final extended64 = [
    ByteOrder.parse('EFGHABCD'),
    ByteOrder.parse('CDABGHEF'),
  ];

  final String pattern;

  /// `permutation[i]` = wire index of the value's i-th most significant byte.
  final List<int> permutation;

  int get width => permutation.length;

  /// Returns the value's bytes, most significant first.
  Uint8List arrange(List<int> wireBytes, [int offset = 0]) {
    if (wireBytes.length - offset < width) {
      throw RangeError(
        'Need $width bytes from offset $offset, '
        'got ${wireBytes.length - offset}',
      );
    }
    return Uint8List.fromList([
      for (final index in permutation) wireBytes[offset + index],
    ]);
  }

  static String _letter(int index) => String.fromCharCode(_letterA + index);

  @override
  bool operator ==(Object other) =>
      other is ByteOrder && other.pattern == pattern;

  @override
  int get hashCode => pattern.hashCode;

  @override
  String toString() => pattern;
}

/// Splits 16-bit registers into wire bytes (high byte first, per Modbus spec).
Uint8List registersToBytes(List<int> registers) {
  final bytes = Uint8List(registers.length * 2);
  for (var i = 0; i < registers.length; i++) {
    final register = registers[i];
    if (register < 0 || register > 0xFFFF) {
      throw RangeError.range(register, 0, 0xFFFF, 'registers[$i]');
    }
    bytes[i * 2] = register >> 8;
    bytes[i * 2 + 1] = register & 0xFF;
  }
  return bytes;
}

/// Joins wire bytes into registers; an odd trailing byte is zero-padded.
List<int> bytesToRegisters(List<int> bytes) => [
  for (var i = 0; i < bytes.length; i += 2)
    (bytes[i] << 8) | (i + 1 < bytes.length ? bytes[i + 1] : 0),
];
