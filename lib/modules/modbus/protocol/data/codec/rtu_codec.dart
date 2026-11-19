import 'dart:typed_data';

import 'package:modbus_explorer/modules/modbus/protocol/data/codec/crc16.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/function_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';

/// Unit ID + 253-byte PDU + CRC.
const maxRtuFrameLength = 256;

/// Signals a function code whose frame length cannot be determined.
const unknownRtuLength = -1;

/// Total RTU frame length (incl. CRC) derived from the bytes seen so far.
///
/// RTU has no length field, so it follows from function code and byte-count
/// fields. Returns `null` if more bytes are needed, [unknownRtuLength] for
/// unknown function codes.
int? rtuFrameLength(List<int> b, {required bool isRequest}) {
  if (b.length < 2) return null;
  final fc = b[1];
  if (fc & FunctionCode.exceptionFlag != 0) {
    return isRequest ? unknownRtuLength : 5;
  }
  int? at(int index, int Function(int value) length) =>
      b.length > index ? length(b[index]) : null;

  if (isRequest) {
    return switch (fc) {
      0x01 || 0x02 || 0x03 || 0x04 || 0x05 || 0x06 => 8,
      0x0F || 0x10 => at(6, (byteCount) => 7 + byteCount + 2),
      0x16 => 10,
      0x17 => at(10, (byteCount) => 11 + byteCount + 2),
      0x2B => 7,
      _ => unknownRtuLength,
    };
  }
  return switch (fc) {
    0x01 ||
    0x02 ||
    0x03 ||
    0x04 ||
    0x17 => at(2, (byteCount) => 3 + byteCount + 2),
    0x05 || 0x06 || 0x0F || 0x10 => 8,
    0x16 => 10,
    0x2B => _deviceIdResponseLength(b),
    _ => unknownRtuLength,
  };
}

/// Device ID responses have a list of length-prefixed objects.
int? _deviceIdResponseLength(List<int> b) {
  const objectCountIndex = 7;
  if (b.length <= objectCountIndex) return null;
  if (b[2] != ReadDeviceIdentificationRequest.meiType) return unknownRtuLength;
  var position = objectCountIndex + 1;
  for (var i = 0; i < b[objectCountIndex]; i++) {
    if (b.length <= position + 1) return null;
    position += 2 + b[position + 1];
    if (position > maxRtuFrameLength) return position;
  }
  return position + 2;
}

final class RtuFraming implements ModbusFraming {
  const new();

  @override
  FrameKind get kind => FrameKind.rtu;

  @override
  Uint8List encodeFrame({
    required int unitId,
    required List<int> pdu,
    int transactionId = 0,
  }) => appendCrc([unitId & 0xFF, ...pdu]);

  @override
  FrameAssembler newAssembler({required bool expectRequests}) =>
      RtuFrameAssembler(expectRequests: expectRequests);
}

final class RtuFrameAssembler implements FrameAssembler {
  new({required this.expectRequests});

  final bool expectRequests;
  final _buffer = <int>[];

  @override
  bool get hasPendingBytes => _buffer.isNotEmpty;

  @override
  List<FramingEvent> addBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    final events = <FramingEvent>[];
    while (_buffer.isNotEmpty) {
      final length = rtuFrameLength(_buffer, isRequest: expectRequests);
      if (length == null) break;
      if (length == unknownRtuLength) {
        events.add(
          FramingError(
            _take(_buffer.length),
            FramingErrorKind.unknownFunctionCode,
          ),
        );
        break;
      }
      if (length > maxRtuFrameLength) {
        events.add(
          FramingError(_take(_buffer.length), FramingErrorKind.frameTooLong),
        );
        break;
      }
      if (_buffer.length < length) break;
      final raw = _take(length);
      events.add(
        hasValidCrc(raw)
            ? DecodedFrame(
                raw: raw,
                unitId: raw[0],
                pdu: Uint8List.sublistView(raw, 1, raw.length - 2),
              )
            : FramingError(raw, FramingErrorKind.crcMismatch),
      );
    }
    return events;
  }

  @override
  List<FramingEvent> flush() {
    if (_buffer.isEmpty) return const [];
    return [
      FramingError(_take(_buffer.length), FramingErrorKind.incompleteFrame),
    ];
  }

  Uint8List _take(int count) {
    final raw = Uint8List.fromList(_buffer.sublist(0, count));
    _buffer.removeRange(0, count);
    return raw;
  }
}

/// Modbus RTU t3.5 silent interval: 3.5 characters of 11 bits, fixed at
/// 1.75 ms above 19200 baud (spec recommendation).
Duration rtuInterFrameDelay(int baudRate) {
  if (baudRate > 19200) return const Duration(microseconds: 1750);
  return Duration(microseconds: (3.5 * 11 * 1000000 / baudRate).ceil());
}
