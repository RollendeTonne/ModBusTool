import 'dart:typed_data';

import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_exception_code.dart';

sealed class ModbusError implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The device rejected the request with an exception response.
final class ModbusDeviceException extends ModbusError {
  new({required this.functionCode, required this.exceptionCode})
    : super(_describe(exceptionCode));

  final int functionCode;
  final int exceptionCode;

  ModbusExceptionCode? get code => ModbusExceptionCode.fromCode(exceptionCode);

  static String _describe(int exceptionCode) {
    final hex = exceptionCode.toRadixString(16).toUpperCase().padLeft(2, '0');
    final name = ModbusExceptionCode.fromCode(exceptionCode)?.specName;
    return 'Modbus exception 0x$hex${name == null ? '' : ' ($name)'}';
  }
}

/// No valid response within the timeout, after all retries.
final class ModbusTimeoutException extends ModbusError {
  new({required this.timeout, required this.attempts})
    : super(
        'No response within ${timeout.inMilliseconds} ms '
        '($attempts attempt${attempts == 1 ? '' : 's'})',
      );

  final Duration timeout;
  final int attempts;
}

/// Category of a connection failure, for localized user messages; the
/// [ModbusError.message] carries the technical detail.
enum ConnectionErrorKind {
  refused,
  timeout,
  hostNotFound,
  unreachable,
  portUnavailable,
  permissionDenied,
  invalidSettings,
  unsupported,
  closed,
  other,
}

/// Transport could not be opened or was closed.
final class ModbusConnectionException extends ModbusError {
  const new(super.message, {this.kind = ConnectionErrorKind.other, this.cause});

  final ConnectionErrorKind kind;
  final Object? cause;
}

/// A response arrived but is malformed (CRC, length, echo mismatch, ...).
final class ModbusProtocolException extends ModbusError {
  const new(super.message, {this.frame});

  final Uint8List? frame;
}
