import 'dart:typed_data';

import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';

/// DateTime's supported range (±100,000,000 days around the epoch).
const _maxDateTimeMillis = 8640000000000000;

/// Decodes [type] from [wireBytes] (starting at [offset]) using [order].
///
/// Returns [InvalidValue] instead of throwing for short input, so a matrix
/// over a partial selection can still be built.
InterpretedValue decodeValue(
  List<int> wireBytes,
  DataType type,
  ByteOrder order, {
  int offset = 0,
}) {
  if (order.width != type.byteWidth) {
    throw ArgumentError(
      'Byte order ${order.pattern} has width ${order.width}, '
      '${type.technicalName} needs ${type.byteWidth}',
    );
  }
  if (wireBytes.length - offset < type.byteWidth) {
    return const InvalidValue(InvalidReason.insufficientData);
  }
  return decodeOrderedBytes(order.arrange(wireBytes, offset), type);
}

/// Decodes bytes that are already most-significant first.
InterpretedValue decodeOrderedBytes(Uint8List bytes, DataType type) {
  assert(bytes.length == type.byteWidth, 'byte count must match type width');
  final data = ByteData.sublistView(bytes);
  return switch (type) {
    DataType.int16 => IntegerValue.fromInt(data.getInt16(0)),
    DataType.uint16 => IntegerValue.fromInt(data.getUint16(0)),
    DataType.int32 => IntegerValue.fromInt(data.getInt32(0)),
    DataType.uint32 => IntegerValue.fromInt(data.getUint32(0)),
    DataType.int64 => IntegerValue(_int64(data)),
    // getUint64 returns a (wrapped) signed int on the VM, so go via BigInt.
    DataType.uint64 => IntegerValue(_int64(data).toUnsigned(64)),
    DataType.float32 => _float32(data),
    DataType.float64 => _float64(data),
    DataType.bcd16 || DataType.bcd32 => _bcd(bytes),
    DataType.unixTime32 => TimestampValue(
      DateTime.fromMillisecondsSinceEpoch(
        data.getUint32(0) * 1000,
        isUtc: true,
      ),
    ),
    DataType.unixTime64Ms => _unixMillis(_int64(data)),
  };
}

BigInt _int64(ByteData data) =>
    (BigInt.from(data.getInt32(0)) << 32) | BigInt.from(data.getUint32(4));

FloatValue _float32(ByteData data) {
  final bits = data.getUint32(0);
  final exponent = (bits >> 23) & 0xFF;
  final mantissa = bits & 0x7FFFFF;
  return FloatValue(
    data.getFloat32(0),
    precision: FloatPrecision.single,
    isDenormal: exponent == 0 && mantissa != 0,
  );
}

FloatValue _float64(ByteData data) {
  final high = data.getUint32(0);
  final low = data.getUint32(4);
  final exponent = (high >> 20) & 0x7FF;
  final mantissaNonZero = (high & 0xFFFFF) != 0 || low != 0;
  return FloatValue(
    data.getFloat64(0),
    precision: FloatPrecision.double,
    isDenormal: exponent == 0 && mantissaNonZero,
  );
}

InterpretedValue _bcd(Uint8List bytes) {
  var result = 0;
  for (final byte in bytes) {
    final high = byte >> 4;
    final low = byte & 0x0F;
    if (high > 9 || low > 9) {
      return const InvalidValue(InvalidReason.invalidBcdDigit);
    }
    result = result * 100 + high * 10 + low;
  }
  return IntegerValue.fromInt(result);
}

InterpretedValue _unixMillis(BigInt millis) {
  if (millis.abs() > BigInt.from(_maxDateTimeMillis)) {
    return const InvalidValue(InvalidReason.timestampOutOfRange);
  }
  return TimestampValue(
    DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true),
  );
}
