import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';

final class SocketChannel implements ByteChannel {
  new(this._socket)
    : description = '${_socket.remoteAddress.address}:${_socket.remotePort}' {
    // Modbus frames are tiny and latency-sensitive; never wait for Nagle.
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _subscription = _socket.listen(
      _input.add,
      onError: (Object e) => _finish(),
      onDone: _finish,
      cancelOnError: true,
    );
  }

  static Future<SocketChannel> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      return SocketChannel(socket);
    } on SocketException catch (e) {
      final (kind, message) = describeSocketError(e, host, port);
      throw ModbusConnectionException(message, kind: kind, cause: e);
    }
  }

  final Socket _socket;
  final _input = StreamController<Uint8List>();
  final _done = Completer<void>();
  late final StreamSubscription<Uint8List> _subscription;

  @override
  final String description;

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> write(Uint8List data) async {
    if (_done.isCompleted) {
      throw const ModbusConnectionException(
        'Connection closed',
        kind: ConnectionErrorKind.closed,
      );
    }
    _socket.add(data);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    _socket.destroy();
    _finish();
  }

  void _finish() {
    if (_done.isCompleted) return;
    _done.complete();
    unawaited(_input.close());
  }
}

/// Error category plus English technical detail; the UI shows a localized
/// text for the category.
(ConnectionErrorKind, String) describeSocketError(
  SocketException e,
  String host,
  int port,
) {
  final code = e.osError?.errorCode;
  final message = e.osError?.message ?? e.message;
  final detail =
      '$host:$port – $message${code == null ? '' : ' (OS error $code)'}';
  // Error codes differ per OS; matching the message is more portable.
  final lower = '$message ${e.message}'.toLowerCase();
  if (lower.contains('refused')) return (ConnectionErrorKind.refused, detail);
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return (ConnectionErrorKind.timeout, detail);
  }
  if (lower.contains('host lookup') ||
      lower.contains('nodename') ||
      lower.contains('not known')) {
    return (ConnectionErrorKind.hostNotFound, detail);
  }
  if (lower.contains('unreachable')) {
    return (ConnectionErrorKind.unreachable, detail);
  }
  return (ConnectionErrorKind.other, detail);
}
