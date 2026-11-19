import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/socket_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/network_scan/domain/arp_parser.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';

/// "Connection refused" error codes: macOS/BSD, Linux, Windows.
const _refusedCodes = {61, 111, 10061};

/// TCP connect probe. A refusal (RST) proves the host is alive even
/// though the port is closed; a timeout means no answer at all.
Future<PortState> probePort(Ipv4 address, int port, Duration timeout) async {
  try {
    final socket = await Socket.connect('$address', port, timeout: timeout);
    socket.destroy();
    return PortState.open;
  } on SocketException catch (e) {
    final code = e.osError?.errorCode;
    final message = (e.osError?.message ?? e.message).toLowerCase();
    if (_refusedCodes.contains(code) || message.contains('refused')) {
      return PortState.closed;
    }
    return PortState.filtered;
  }
}

/// MAC addresses from the operating system's ARP cache; empty where not
/// available (mobile platforms, sandbox restrictions).
Future<Map<Ipv4, String>> readArpTable() async {
  try {
    final String output;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        output = await File('/proc/net/arp').readAsString();
      case TargetPlatform.macOS:
        output = (await Process.run('/usr/sbin/arp', ['-an'])).stdout as String;
      case TargetPlatform.windows:
        output = (await Process.run('arp', ['-a'])).stdout as String;
      case TargetPlatform.android ||
          TargetPlatform.iOS ||
          TargetPlatform.fuchsia:
        return const {};
    }
    return parseArpTable(output);
  } on Object {
    return const {};
  }
}

/// Reverse DNS with a timeout; `null` if there is no name.
Future<String?> reverseLookup(Ipv4 address, Duration timeout) async {
  try {
    final result = await InternetAddress('$address').reverse().timeout(timeout);
    final host = result.host;
    return host.isEmpty || host == '$address' ? null : host;
  } on Object {
    return null;
  }
}

/// Own IPv4 addresses per interface (for range suggestions).
Future<List<({String interface, Ipv4 address})>> localIpv4Addresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return [
      for (final i in interfaces)
        for (final a in i.addresses)
          if (Ipv4.tryParse(a.address) case final ip?)
            (interface: i.name, address: ip),
    ];
  } on Object {
    return const [];
  }
}

/// Verifies that an open port speaks Modbus TCP: Read Device
/// Identification first (gives vendor/product), then a plain register read.
/// Any answer, including an exception response, counts.
Future<ModbusIdentity?> probeModbus(
  Ipv4 address,
  int port,
  Duration timeout,
) async {
  SocketChannel channel;
  try {
    channel = await SocketChannel.connect('$address', port, timeout: timeout);
  } on Object {
    return null;
  }
  // Modbus answers take longer than a TCP handshake; no retries in scans.
  final client = ModbusClient(
    channel: channel,
    framing: const MbapFraming(),
    defaults: RequestOptions(timeout: timeout * 3, retries: 0),
  );
  try {
    try {
      final id = await client.execute(
        ReadDeviceIdentificationRequest(),
        unitId: 1,
      );
      if (id case DeviceIdentificationResponse()) {
        return ModbusIdentity(
          port: port,
          vendor: id.text(DeviceIdObject.vendorName),
          product: id.text(DeviceIdObject.productCode),
          revision: id.text(DeviceIdObject.majorMinorRevision),
        );
      }
    } on ModbusDeviceException catch (e) {
      // FC43 not supported is common; the device still speaks Modbus.
      return ModbusIdentity(port: port, exceptionCode: e.exceptionCode);
    } on ModbusError {
      // Fall through to a register read with the TCP "this device" unit.
    }
    try {
      await client.readHoldingRegisters(0, 1, unitId: 255);
      return ModbusIdentity(port: port);
    } on ModbusDeviceException catch (e) {
      return ModbusIdentity(port: port, exceptionCode: e.exceptionCode);
    } on ModbusError {
      return null;
    }
  } finally {
    await client.close();
  }
}
