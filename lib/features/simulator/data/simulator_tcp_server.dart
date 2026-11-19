import 'dart:async';
import 'dart:io';

import 'package:modbus_explorer/features/modbus/data/channel/socket_channel.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_endpoint.dart';

/// Real Modbus TCP server so external tools can talk to the simulator.
final class SimulatorTcpServer {
  new _(this._server, this._bank, this._framing, this.faults) {
    _server.listen(_accept);
  }

  /// Port 502 needs root on Unix-like systems.
  static const defaultPort = 1502;

  static Future<SimulatorTcpServer> start({
    required SimulatorBank bank,
    int port = defaultPort,
    bool exposeOnNetwork = false,
    ModbusFraming framing = const MbapFraming(),
    SimulatorFaults? faults,
  }) async {
    final server = await ServerSocket.bind(
      exposeOnNetwork ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4,
      port,
    );
    return SimulatorTcpServer._(
      server,
      bank,
      framing,
      faults ?? SimulatorFaults(),
    );
  }

  final ServerSocket _server;
  final SimulatorBank _bank;
  final ModbusFraming _framing;
  final SimulatorFaults faults;
  final _endpoints = <SimulatorEndpoint>{};

  int get port => _server.port;
  InternetAddress get address => _server.address;
  int get connectionCount => _endpoints.length;

  void _accept(Socket socket) {
    final channel = SocketChannel(socket);
    final endpoint = SimulatorEndpoint(
      channel: channel,
      framing: _framing,
      bank: _bank,
      faults: faults,
    );
    _endpoints.add(endpoint);
    unawaited(channel.done.then((_) => _endpoints.remove(endpoint)));
  }

  Future<void> stop() async {
    await _server.close();
    await Future.wait([for (final e in _endpoints.toList()) e.close()]);
    _endpoints.clear();
  }
}
