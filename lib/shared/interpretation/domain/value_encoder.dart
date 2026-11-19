import 'dart:typed_data';

import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';

/// Encodes a user-entered value as wire bytes for [type] in [order] – the
/// inverse of `decodeValue`, used to prepare register values for writing.
///
/// Integers accept decimal or `0x` hex; timestamps accept seconds/millis
/// or an ISO 8601 date. Throws [FormatException] for unparsable or
/// out-of-range input.
Uint8List encodeValue(DataType type, ByteOrder order, String input) {
  if (order.width != type.byteWidth) {
    throw ArgumentError('Byte order ${order.pattern} does not fit $type');
  }
  final text = input.trim();
  if (text.isEmpty) throw FormatException('Empty value', input);
  final ordered = _orderedBytes(type, text);
  final wire = Uint8List(type.byteWidth);
  for (var i = 0; i < ordered.length; i++) {
    wire[order.permutation[i]] = ordered[i];
  }
  return wire;
}

Uint8List _orderedBytes(DataType type, String text) {
  final data = ByteData(type.byteWidth);
  switch (type) {
    case DataType.int16:
      data.setInt16(0, _int(text, -0x8000, 0x7FFF).toInt());
    case DataType.uint16:
      data.setUint16(0, _int(text, 0, 0xFFFF).toInt());
    case DataType.int32:
      data.setInt32(0, _int(text, -0x80000000, 0x7FFFFFFF).toInt());
    case DataType.uint32:
      data.setUint32(0, _int(text, 0, 0xFFFFFFFF).toInt());
    case DataType.int64:
      _setBig(
        data,
        _big(text, BigInt.from(-1) << 63, (BigInt.one << 63) - BigInt.one),
      );
    case DataType.uint64:
      _setBig(data, _big(text, BigInt.zero, (BigInt.one << 64) - BigInt.one));
    case DataType.float32:
      data.setFloat32(0, _double(text));
    case DataType.float64:
      data.setFloat64(0, _double(text));
    case DataType.bcd16 || DataType.bcd32:
      return _bcd(text, type.byteWidth);
    case DataType.unixTime32:
      data.setUint32(0, _timestamp(text, millis: false, max: 0xFFFFFFFF));
    case DataType.unixTime64Ms:
      _setBig(data, BigInt.from(_timestamp(text, millis: true)));
  }
  return data.buffer.asUint8List();
}

BigInt _big(String text, BigInt min, BigInt max) {
  final lower = text.toLowerCase();
  final negative = lower.startsWith('-');
  final digits = negative ? lower.substring(1) : lower;
  final value = digits.startsWith('0x')
      ? BigInt.tryParse(digits.substring(2), radix: 16)
      : BigInt.tryParse(digits);
  if (value == null) throw FormatException('Not an integer', text);
  final signed = negative ? -value : value;
  if (signed < min || signed > max) {
    throw FormatException('Out of range $min…$max', text);
  }
  return signed;
}

BigInt _int(String text, int min, int max) =>
    _big(text, BigInt.from(min), BigInt.from(max));

void _setBig(ByteData data, BigInt value) {
  final unsigned = value.toUnsigned(64);
  data
    ..setUint32(0, (unsigned >> 32).toInt())
    ..setUint32(4, (unsigned & BigInt.from(0xFFFFFFFF)).toInt());
}

double _double(String text) {
  final normalized = text.replaceAll(',', '.');
  final value = switch (normalized.toLowerCase()) {
    'nan' => double.nan,
    'inf' || '+inf' || 'infinity' => double.infinity,
    '-inf' || '-infinity' => double.negativeInfinity,
    _ => double.tryParse(normalized),
  };
  if (value == null) throw FormatException('Not a number', text);
  return value;
}

Uint8List _bcd(String text, int width) {
  final digits = text.replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^\d+$').hasMatch(digits) || digits.length > width * 2) {
    throw FormatException('BCD needs up to ${width * 2} decimal digits', text);
  }
  final padded = digits.padLeft(width * 2, '0');
  return Uint8List.fromList([
    for (var i = 0; i < width * 2; i += 2)
      (int.parse(padded[i]) << 4) | int.parse(padded[i + 1]),
  ]);
}

int _timestamp(String text, {required bool millis, int? max}) {
  final number = int.tryParse(text);
  final int value;
  if (number != null) {
    value = number;
  } else {
    final date = DateTime.tryParse(text);
    if (date == null) throw FormatException('Not a timestamp', text);
    final ms = date.toUtc().millisecondsSinceEpoch;
    value = millis ? ms : ms ~/ 1000;
  }
  if ((!millis && value < 0) || (max != null && value > max)) {
    throw FormatException('Timestamp out of range', text);
  }
  return value;
}
