import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/data/codec/crc16.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/function_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';

/// Field kinds; the UI maps them to localized labels.
enum SegmentKind {
  transactionId,
  protocolId,
  length,
  unitId,
  functionCode,
  exceptionCode,
  address,
  count,
  byteCount,
  value,
  valueList,
  andMask,
  orMask,
  readAddress,
  readCount,
  writeAddress,
  writeCount,
  meiType,
  deviceIdCode,
  objectId,
  conformityLevel,
  moreFollows,
  nextObjectId,
  objectCount,
  object,
  data,
  crc,
  truncated,
  trailing,
}

@immutable
final class FrameSegment {
  const new({
    required this.kind,
    required this.offset,
    required this.length,
    required this.display,
    this.isValid = true,
  });

  final SegmentKind kind;

  /// Byte range within the frame, for highlighting in the hex dump.
  final int offset;
  final int length;

  /// Language-neutral decoded value, e.g. `0x006B (107)`.
  final String display;
  final bool isValid;

  @override
  String toString() => '$kind@$offset+$length: $display${isValid ? '' : ' !'}';
}

@immutable
final class FrameDissection {
  const new({
    required this.segments,
    this.functionCode,
    this.isException = false,
    this.crcValid,
  });

  final List<FrameSegment> segments;
  final int? functionCode;
  final bool isException;

  /// `null` for TCP frames.
  final bool? crcValid;

  bool get isComplete => segments.every(
    (s) => s.kind != SegmentKind.truncated && s.kind != SegmentKind.trailing,
  );
}

/// Breaks a raw TCP or RTU frame into labelled fields. Never throws; broken
/// frames produce `truncated`/`trailing` segments instead.
FrameDissection dissectFrame(
  List<int> bytes,
  FrameKind kind, {
  required bool isRequest,
}) {
  final out = _SegmentWriter(bytes);
  bool? crcValid;
  var pduEnd = bytes.length;

  if (kind == FrameKind.tcp) {
    out
      ..u16(SegmentKind.transactionId)
      ..u16(SegmentKind.protocolId, validate: (v) => v == 0)
      ..u16(SegmentKind.length)
      ..u8(SegmentKind.unitId);
    if (bytes.length >= mbapHeaderLength) {
      final declared = (bytes[4] << 8) | bytes[5];
      final actual = bytes.length - 6;
      if (declared != actual) out.markInvalid(SegmentKind.length);
    }
  } else {
    out.u8(SegmentKind.unitId);
    if (bytes.length >= 4) {
      pduEnd = bytes.length - 2;
      crcValid = hasValidCrc(bytes);
    }
  }

  int? fc;
  var isException = false;
  if (!out.failed && out.position < pduEnd) {
    fc = bytes[out.position];
    isException = fc & FunctionCode.exceptionFlag != 0;
    out
      ..add(SegmentKind.functionCode, 1, _functionCodeText(fc))
      ..limit = pduEnd;
    if (isException) {
      out.u8(SegmentKind.exceptionCode, format: _exceptionText);
    } else {
      _dissectPdu(out, fc, isRequest: isRequest);
    }
    out.trailing();
  } else if (!out.failed && kind == FrameKind.rtu) {
    out.truncated();
  }

  if (kind == FrameKind.rtu && bytes.length >= 4) {
    final n = bytes.length;
    final received = bytes[n - 2] | (bytes[n - 1] << 8);
    final expected = crc16Modbus(bytes, 0, n - 2);
    String hex(int v) => '0x${formatHex(v, prefix: false)}';
    out.segments.add(
      FrameSegment(
        kind: SegmentKind.crc,
        offset: n - 2,
        length: 2,
        // Shown as the 16-bit value (wire order is low byte first).
        display: crcValid!
            ? hex(received)
            : '${hex(received)} ≠ ${hex(expected)}',
        isValid: crcValid,
      ),
    );
  }

  return FrameDissection(
    segments: List.unmodifiable(out.segments),
    functionCode: fc,
    isException: isException,
    crcValid: crcValid,
  );
}

void _dissectPdu(_SegmentWriter out, int fc, {required bool isRequest}) {
  switch ((fc, isRequest)) {
    case (0x01 || 0x02 || 0x03 || 0x04, true):
      out
        ..u16(SegmentKind.address)
        ..u16(SegmentKind.count);
    case (0x01 || 0x02, false):
      final count = out.u8(SegmentKind.byteCount);
      if (count != null) out.bits(SegmentKind.valueList, count);
    case (0x03 || 0x04 || 0x17, false):
      final count = out.u8(SegmentKind.byteCount);
      if (count != null) out.registers(SegmentKind.valueList, count);
    case (0x05 || 0x06, _):
      out
        ..u16(SegmentKind.address)
        ..u16(SegmentKind.value);
    case (0x0F || 0x10, true):
      out
        ..u16(SegmentKind.address)
        ..u16(SegmentKind.count);
      final count = out.u8(SegmentKind.byteCount);
      if (count != null) {
        fc == 0x0F
            ? out.bits(SegmentKind.valueList, count)
            : out.registers(SegmentKind.valueList, count);
      }
    case (0x0F || 0x10, false):
      out
        ..u16(SegmentKind.address)
        ..u16(SegmentKind.count);
    case (0x16, _):
      out
        ..u16(SegmentKind.address)
        ..u16(SegmentKind.andMask)
        ..u16(SegmentKind.orMask);
    case (0x17, true):
      out
        ..u16(SegmentKind.readAddress)
        ..u16(SegmentKind.readCount)
        ..u16(SegmentKind.writeAddress)
        ..u16(SegmentKind.writeCount);
      final count = out.u8(SegmentKind.byteCount);
      if (count != null) out.registers(SegmentKind.valueList, count);
    case (0x2B, true):
      out
        ..u8(SegmentKind.meiType)
        ..u8(SegmentKind.deviceIdCode)
        ..u8(SegmentKind.objectId);
    case (0x2B, false):
      out
        ..u8(SegmentKind.meiType)
        ..u8(SegmentKind.deviceIdCode)
        ..u8(SegmentKind.conformityLevel)
        ..u8(SegmentKind.moreFollows)
        ..u8(SegmentKind.nextObjectId);
      final objects = out.u8(SegmentKind.objectCount);
      for (var i = 0; i < (objects ?? 0) && !out.failed; i++) {
        out.deviceIdObject();
      }
    default:
      out.rest(SegmentKind.data);
  }
}

String _functionCodeText(int fc) {
  final base = fc & ~FunctionCode.exceptionFlag;
  final name = FunctionCode.fromCode(base)?.name ?? 'unknown';
  final hex = formatHex(fc, digits: 2);
  return fc & FunctionCode.exceptionFlag != 0
      ? '$hex (exception, $name)'
      : '$hex ($name)';
}

String _exceptionText(int code) {
  final name = ModbusExceptionCode.fromCode(code)?.specName ?? 'unknown';
  return '${formatHex(code, digits: 2)} ($name)';
}

final class _SegmentWriter {
  new(this.bytes) : limit = bytes.length;

  final List<int> bytes;
  final segments = <FrameSegment>[];
  int position = 0;
  int limit;
  bool failed = false;

  int get _available => limit - position;

  void add(SegmentKind kind, int length, String display, {bool valid = true}) {
    segments.add(
      FrameSegment(
        kind: kind,
        offset: position,
        length: length,
        display: display,
        isValid: valid,
      ),
    );
    position += length;
  }

  int? u8(SegmentKind kind, {String Function(int)? format}) {
    if (failed) return null;
    if (_available < 1) {
      truncated();
      return null;
    }
    final v = bytes[position];
    add(kind, 1, format?.call(v) ?? '${formatHex(v, digits: 2)} ($v)');
    return v;
  }

  int? u16(SegmentKind kind, {bool Function(int)? validate}) {
    if (failed) return null;
    if (_available < 2) {
      truncated();
      return null;
    }
    final v = (bytes[position] << 8) | bytes[position + 1];
    add(kind, 2, '${formatHex(v)} ($v)', valid: validate?.call(v) ?? true);
    return v;
  }

  void registers(SegmentKind kind, int byteCount) {
    if (failed) return;
    final length = byteCount <= _available ? byteCount : _available;
    final values = [
      for (var i = 0; i + 1 < length; i += 2)
        formatHex((bytes[position + i] << 8) | bytes[position + i + 1]),
    ];
    add(kind, length, values.join(' '), valid: length == byteCount);
    if (length < byteCount) truncated();
  }

  void bits(SegmentKind kind, int byteCount) {
    if (failed) return;
    final length = byteCount <= _available ? byteCount : _available;
    // LSB first per byte, matching address order.
    final text = [
      for (var i = 0; i < length; i++)
        bytes[position + i]
            .toRadixString(2)
            .padLeft(8, '0')
            .split('')
            .reversed
            .join(),
    ].join(' ');
    add(kind, length, text, valid: length == byteCount);
    if (length < byteCount) truncated();
  }

  void deviceIdObject() {
    if (_available < 2) {
      truncated();
      return;
    }
    final id = bytes[position];
    final length = bytes[position + 1];
    if (_available < 2 + length) {
      truncated();
      return;
    }
    final text = String.fromCharCodes(
      bytes.sublist(position + 2, position + 2 + length),
    );
    add(SegmentKind.object, 2 + length, '${formatHex(id, digits: 2)}: $text');
  }

  void rest(SegmentKind kind) {
    if (failed || _available <= 0) return;
    add(kind, _available, formatHexBytes(bytes.sublist(position, limit)));
  }

  void markInvalid(SegmentKind kind) {
    final index = segments.indexWhere((s) => s.kind == kind);
    if (index < 0) return;
    final s = segments[index];
    segments[index] = FrameSegment(
      kind: s.kind,
      offset: s.offset,
      length: s.length,
      display: s.display,
      isValid: false,
    );
  }

  void truncated() {
    if (failed) return;
    failed = true;
    segments.add(
      FrameSegment(
        kind: SegmentKind.truncated,
        offset: position,
        length: _available.clamp(0, bytes.length),
        display: _available > 0
            ? formatHexBytes(bytes.sublist(position, limit))
            : '',
        isValid: false,
      ),
    );
    position = limit;
  }

  void trailing() {
    if (failed || _available <= 0) return;
    add(
      SegmentKind.trailing,
      _available,
      formatHexBytes(bytes.sublist(position, limit)),
      valid: false,
    );
  }
}
