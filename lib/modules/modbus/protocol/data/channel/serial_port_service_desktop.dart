import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/byte_channel.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';

/// Windows/Linux/macOS via libserialport (FFI).
final class DesktopSerialPortService implements SerialPortService {
  const new();

  @override
  bool get isSupported => true;

  @override
  Future<List<SerialPortInfo>> listPorts() async {
    final ports = <SerialPortInfo>[];
    for (final name in SerialPort.availablePorts) {
      final port = SerialPort(name);
      try {
        ports.add(
          SerialPortInfo(
            name: name,
            description: _safe(() => port.description),
            manufacturer: _safe(() => port.manufacturer),
            serialNumber: _safe(() => port.serialNumber),
            vendorId: _safe(() => port.vendorId),
            productId: _safe(() => port.productId),
          ),
        );
      } finally {
        port.dispose();
      }
    }
    return ports;
  }

  @override
  Future<ByteChannel> open(SerialSettings settings) async {
    final port = SerialPort(settings.portName);
    if (!port.openReadWrite()) {
      final error = SerialPort.lastError;
      port.dispose();
      final message = error?.message ?? 'unknown error';
      final lower = message.toLowerCase();
      throw ModbusConnectionException(
        'Cannot open ${settings.portName}: $message',
        kind: lower.contains('permission') || lower.contains('access')
            ? ConnectionErrorKind.permissionDenied
            : ConnectionErrorKind.portUnavailable,
        cause: error,
      );
    }
    final config = SerialPortConfig()
      ..baudRate = settings.baudRate
      ..bits = settings.dataBits
      ..stopBits = settings.stopBits
      ..parity = switch (settings.parity) {
        SerialParity.none => SerialPortParity.none,
        SerialParity.even => SerialPortParity.even,
        SerialParity.odd => SerialPortParity.odd,
      }
      ..setFlowControl(SerialPortFlowControl.none);
    if (settings.rts != SerialLineMode.unchanged) {
      config.rts = settings.rts == SerialLineMode.on
          ? SerialPortRts.on
          : SerialPortRts.off;
    }
    if (settings.dtr != SerialLineMode.unchanged) {
      config.dtr = settings.dtr == SerialLineMode.on
          ? SerialPortDtr.on
          : SerialPortDtr.off;
    }
    try {
      port.config = config;
    } on SerialPortError catch (e) {
      port
        ..close()
        ..dispose();
      throw ModbusConnectionException(
        'Unsupported settings ${settings.shortDescription} for '
        '${settings.portName}: ${e.message}',
        kind: ConnectionErrorKind.invalidSettings,
        cause: e,
      );
    } finally {
      config.dispose();
    }
    return _LibSerialPortChannel(port, settings.portName);
  }

  static T? _safe<T>(T? Function() read) {
    try {
      return read();
    } on Object {
      // Some drivers don't expose USB metadata; that's informational only.
      return null;
    }
  }
}

final class _LibSerialPortChannel implements ByteChannel {
  new(this._port, this.description) : _reader = SerialPortReader(_port) {
    _subscription = _reader.stream.listen(
      _input.add,
      onError: (Object _) => unawaited(close()),
      onDone: () => unawaited(close()),
    );
  }

  final SerialPort _port;
  final SerialPortReader _reader;
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
        'Serial port closed',
        kind: ConnectionErrorKind.closed,
      );
    }
    // Blocking write with timeout; frames are ≤ 256 bytes so this is short.
    final written = _port.write(data, timeout: 1000);
    if (written != data.length) {
      throw ModbusConnectionException(
        'Serial write incomplete ($written/${data.length} bytes)',
      );
    }
  }

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    await _subscription.cancel();
    _reader.close();
    _port
      ..close()
      ..dispose();
    await _input.close();
  }
}
