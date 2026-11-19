import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/byte_channel.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';

@immutable
final class SerialPortInfo {
  const new({
    required this.name,
    this.description,
    this.manufacturer,
    this.serialNumber,
    this.vendorId,
    this.productId,
  });

  /// Identifier used to open the port (path, COM name or Android device).
  final String name;
  final String? description;
  final String? manufacturer;
  final String? serialNumber;
  final int? vendorId;
  final int? productId;

  @override
  bool operator ==(Object other) =>
      other is SerialPortInfo && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

abstract interface class SerialPortService {
  bool get isSupported;

  Future<List<SerialPortInfo>> listPorts();

  /// Throws [ModbusConnectionException] if the port cannot be opened.
  Future<ByteChannel> open(SerialSettings settings);
}

final class UnsupportedSerialPortService implements SerialPortService {
  const new();

  @override
  bool get isSupported => false;

  @override
  Future<List<SerialPortInfo>> listPorts() async => const [];

  @override
  Future<ByteChannel> open(SerialSettings settings) => Future.error(
    const ModbusConnectionException(
      'Serial ports are not supported on this platform',
      kind: ConnectionErrorKind.unsupported,
    ),
  );
}
