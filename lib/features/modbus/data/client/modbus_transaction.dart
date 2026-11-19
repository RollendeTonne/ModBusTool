import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';

/// Outcome of one `execute` call including retries (log + statistics).
@immutable
final class ModbusTransaction {
  const new({
    required this.number,
    required this.unitId,
    required this.request,
    required this.startedAt,
    required this.duration,
    required this.attempts,
    this.latency,
    this.response,
    this.error,
  });

  final int number;
  final int unitId;
  final ModbusRequest request;
  final DateTime startedAt;

  /// Wall time including retries and queueing on the wire.
  final Duration duration;

  /// Round trip of the attempt that produced a response.
  final Duration? latency;
  final int attempts;
  final ModbusResponse? response;
  final ModbusError? error;

  bool get isSuccess => error == null;
}
