import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/modbus_providers.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_tcp_server.dart';

@immutable
final class SimulatorServerState {
  const new({
    this.server,
    this.port = SimulatorTcpServer.defaultPort,
    this.exposeOnNetwork = false,
    this.isStarting = false,
    this.error,
  });

  final SimulatorTcpServer? server;
  final int port;
  final bool exposeOnNetwork;
  final bool isStarting;
  final Object? error;

  bool get isRunning => server != null;
}

final class SimulatorServerController extends Notifier<SimulatorServerState> {
  /// Mirrors the server in [state]; `state` is not readable in onDispose.
  SimulatorTcpServer? _server;

  @override
  SimulatorServerState build() {
    ref.onDispose(() => unawaited(_server?.stop()));
    return const SimulatorServerState();
  }

  Future<void> start({int? port, bool? exposeOnNetwork}) async {
    if (state.isRunning || state.isStarting) return;
    final targetPort = port ?? state.port;
    final expose = exposeOnNetwork ?? state.exposeOnNetwork;
    state = SimulatorServerState(
      port: targetPort,
      exposeOnNetwork: expose,
      isStarting: true,
    );
    try {
      final server = await SimulatorTcpServer.start(
        bank: ref.read(simulatorBankProvider),
        port: targetPort,
        exposeOnNetwork: expose,
      );
      _server = server;
      state = SimulatorServerState(
        server: server,
        port: server.port,
        exposeOnNetwork: expose,
      );
    } on Object catch (e) {
      state = SimulatorServerState(
        port: targetPort,
        exposeOnNetwork: expose,
        error: e,
      );
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    state = SimulatorServerState(
      port: state.port,
      exposeOnNetwork: state.exposeOnNetwork,
    );
    await server?.stop();
  }

  void setPort(int port) {
    if (!state.isRunning) {
      state = SimulatorServerState(
        port: port,
        exposeOnNetwork: state.exposeOnNetwork,
      );
    }
  }

  void setExposeOnNetwork({required bool expose}) {
    if (!state.isRunning) {
      state = SimulatorServerState(port: state.port, exposeOnNetwork: expose);
    }
  }
}

final simulatorServerControllerProvider =
    NotifierProvider<SimulatorServerController, SimulatorServerState>(
      SimulatorServerController.new,
    );
