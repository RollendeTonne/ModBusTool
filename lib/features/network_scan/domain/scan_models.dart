import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

/// What a Modbus request to an open port revealed.
@immutable
final class ModbusIdentity {
  const new({
    required this.port,
    this.vendor,
    this.product,
    this.revision,
    this.exceptionCode,
  });

  final int port;
  final String? vendor;
  final String? product;
  final String? revision;

  /// Device answered with an exception – still a Modbus device.
  final int? exceptionCode;

  String get summary =>
      [vendor, product, revision].whereType<String>().join(' ');
}

@immutable
final class HostResult {
  const new({
    required this.address,
    this.hostname,
    this.mac,
    this.openPorts = const [],
    this.modbus,
    this.isLocal = false,
  });

  final Ipv4 address;
  final String? hostname;
  final String? mac;
  final List<int> openPorts;
  final ModbusIdentity? modbus;

  /// One of this device's own addresses.
  final bool isLocal;

  HostResult copyWith({
    String? hostname,
    String? mac,
    List<int>? openPorts,
    ModbusIdentity? modbus,
    bool? isLocal,
  }) => HostResult(
    address: address,
    hostname: hostname ?? this.hostname,
    mac: mac ?? this.mac,
    openPorts: openPorts ?? this.openPorts,
    modbus: modbus ?? this.modbus,
    isLocal: isLocal ?? this.isLocal,
  );
}

enum PortState { open, closed, filtered }
