import 'dart:typed_data';

import 'package:meta/meta.dart';

enum FrameKind {
  /// Modbus TCP with MBAP header.
  tcp,

  /// Modbus RTU (serial or RTU-over-TCP) with CRC.
  rtu,
}

enum FramingErrorKind {
  crcMismatch,
  invalidHeader,
  unknownFunctionCode,
  incompleteFrame,
  frameTooLong,
}

@immutable
sealed class FramingEvent {
  const new(this.raw);

  /// Exact bytes as received (for the monitor).
  final Uint8List raw;
}

final class DecodedFrame extends FramingEvent {
  const new({
    required Uint8List raw,
    required this.unitId,
    required this.pdu,
    this.transactionId,
  }) : super(raw);

  final int unitId;
  final Uint8List pdu;

  /// MBAP transaction ID; `null` for RTU.
  final int? transactionId;
}

final class FramingError extends FramingEvent {
  const new(super.raw, this.kind);

  final FramingErrorKind kind;
}

/// Turns a byte stream into frames. Stateful, one per connection direction.
abstract interface class FrameAssembler {
  List<FramingEvent> addBytes(List<int> bytes);

  /// Called after line silence/timeout: leftovers become an error event.
  List<FramingEvent> flush();

  bool get hasPendingBytes;
}

abstract interface class ModbusFraming {
  FrameKind get kind;

  Uint8List encodeFrame({
    required int unitId,
    required List<int> pdu,
    int transactionId = 0,
  });

  /// [expectRequests] selects request (server) or response (client)
  /// length rules – RTU frames carry no length field.
  FrameAssembler newAssembler({required bool expectRequests});
}
