import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';

enum FrameDirection { tx, rx }

enum FrameStatus {
  ok,
  crcError,
  malformed,

  /// Valid frame that matches no pending request (late or foreign answer).
  unexpected,
  incomplete,
}

/// One raw frame on the wire, for the communication monitor.
@immutable
final class FrameEvent {
  const new({
    required this.timestamp,
    required this.direction,
    required this.kind,
    required this.bytes,
    this.status = FrameStatus.ok,
    this.transactionNumber,
  });

  final DateTime timestamp;
  final FrameDirection direction;
  final FrameKind kind;
  final Uint8List bytes;
  final FrameStatus status;

  /// Links the frame to a `ModbusTransaction.number`.
  final int? transactionNumber;

  bool get isRequest => direction == FrameDirection.tx;
}
