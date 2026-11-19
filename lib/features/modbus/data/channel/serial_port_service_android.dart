import 'dart:async';
import 'dart:typed_data';

import 'package:modbus_explorer/features/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:usb_serial/usb_serial.dart';

/// Android USB-OTG adapters (FTDI, CH34x, CP210x, PL2303, CDC).
final class AndroidSerialPortService implements SerialPortService {
  const new();

  @override
  bool get isSupported => true;

  @override
  Future<List<SerialPortInfo>> listPorts() async {
    final devices = await UsbSerial.listDevices();
    return [
      for (final d in devices)
        SerialPortInfo(
          name: d.deviceName,
          description: d.productName,
          manufacturer: d.manufacturerName,
          serialNumber: d.serial,
          vendorId: d.vid,
          productId: d.pid,
        ),
    ];
  }

  @override
  Future<ByteChannel> open(SerialSettings settings) async {
    final devices = await UsbSerial.listDevices();
    final device = devices
        .where((d) => d.deviceName == settings.portName)
        .firstOrNull;
    if (device == null) {
      throw ModbusConnectionException(
        'USB device ${settings.portName} not found',
        kind: ConnectionErrorKind.portUnavailable,
      );
    }
    // create() triggers the Android USB permission dialog if needed.
    final port = await device.create();
    if (port == null || !await port.open()) {
      throw ModbusConnectionException(
        'Cannot open ${device.productName ?? settings.portName}',
        kind: ConnectionErrorKind.permissionDenied,
      );
    }
    await port.setPortParameters(
      settings.baudRate,
      settings.dataBits,
      switch (settings.stopBits) {
        2 => UsbPort.STOPBITS_2,
        _ => UsbPort.STOPBITS_1,
      },
      switch (settings.parity) {
        SerialParity.none => UsbPort.PARITY_NONE,
        SerialParity.even => UsbPort.PARITY_EVEN,
        SerialParity.odd => UsbPort.PARITY_ODD,
      },
    );
    await port.setFlowControl(UsbPort.FLOW_CONTROL_OFF);
    if (settings.rts != SerialLineMode.unchanged) {
      await port.setRTS(settings.rts == SerialLineMode.on);
    }
    if (settings.dtr != SerialLineMode.unchanged) {
      await port.setDTR(settings.dtr == SerialLineMode.on);
    }
    return _UsbSerialChannel(port, device.productName ?? settings.portName);
  }
}

final class _UsbSerialChannel implements ByteChannel {
  new(this._port, this.description) {
    _subscription = _port.inputStream?.listen(
      _input.add,
      onError: (Object _) => unawaited(close()),
      onDone: () => unawaited(close()),
    );
  }

  final UsbPort _port;
  final _input = StreamController<Uint8List>();
  final _done = Completer<void>();
  StreamSubscription<Uint8List>? _subscription;

  @override
  final String description;

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> write(Uint8List data) {
    if (_done.isCompleted) {
      throw const ModbusConnectionException(
        'USB serial port closed',
        kind: ConnectionErrorKind.closed,
      );
    }
    return _port.write(data);
  }

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    await _subscription?.cancel();
    await _port.close();
    await _input.close();
  }
}
