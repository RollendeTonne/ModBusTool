import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/byte_channel.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';

/// Lists fixed ports; opening always fails like an unplugged adapter.
final class FakeSerialPortService implements SerialPortService {
  const new({this.ports = defaultPorts});

  static const defaultPorts = [
    SerialPortInfo(name: '/dev/cu.Bluetooth-Incoming-Port'),
    SerialPortInfo(
      name: '/dev/ttyUSB0',
      description: 'USB-RS485',
      manufacturer: 'FTDI',
      vendorId: 0x0403,
      productId: 0x6001,
    ),
  ];

  final List<SerialPortInfo> ports;

  @override
  bool get isSupported => true;

  @override
  Future<List<SerialPortInfo>> listPorts() async => ports;

  @override
  Future<ByteChannel> open(SerialSettings settings) => Future.error(
    ModbusConnectionException(
      'Cannot open ${settings.portName}',
      kind: ConnectionErrorKind.portUnavailable,
    ),
  );
}
