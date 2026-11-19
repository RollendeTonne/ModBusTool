import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_status.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_status_provider.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_tcp_server.dart';

import '../../../helpers/container.dart';

ConnectionProfile profileFor(
  ConnectionConfig config, {
  bool autoReconnect = false,
}) => ConnectionProfile(
  id: 'p1',
  name: 'Test',
  config: config,
  createdAt: DateTime.utc(2026),
  autoReconnect: autoReconnect,
);

Future<void> waitFor(bool Function() condition, {int maxMs = 5000}) async {
  final watch = Stopwatch()..start();
  while (!condition()) {
    if (watch.elapsedMilliseconds > maxMs) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('connect and disconnect the simulator', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final controller = container.read(connectionControllerProvider.notifier);
    expect(
      container.read(connectionStatusProvider),
      ConnectionStatus.disconnected,
    );

    await controller.connect(profileFor(const SimulatorConnectionConfig()));
    expect(container.read(connectionControllerProvider), isA<Connected>());
    expect(
      container.read(connectionStatusProvider),
      ConnectionStatus.connected,
    );
    final client = container.read(activeClientProvider)!;
    expect(await client.readHoldingRegisters(25, 1), [0x1234]);

    await controller.disconnect();
    expect(container.read(connectionControllerProvider), isA<Disconnected>());
    expect(container.read(activeClientProvider), isNull);
    expect(client.isClosed, isTrue);
  });

  test('refused TCP connection ends in ConnectionFailed', () async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    final port = server.port;
    await server.stop();
    final container = createTestContainer();
    addTearDown(container.dispose);
    await container
        .read(connectionControllerProvider.notifier)
        .connect(
          profileFor(TcpConnectionConfig(host: '127.0.0.1', port: port)),
        );
    final state = container.read(connectionControllerProvider);
    expect(state, isA<ConnectionFailed>());
    expect(
      ((state as ConnectionFailed).error as ModbusConnectionException).kind,
      ConnectionErrorKind.refused,
    );
    expect(container.read(connectionStatusProvider), ConnectionStatus.error);
  });

  test('lost connection without auto-reconnect is reported', () async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    final container = createTestContainer();
    addTearDown(container.dispose);
    await container
        .read(connectionControllerProvider.notifier)
        .connect(
          profileFor(TcpConnectionConfig(host: '127.0.0.1', port: server.port)),
        );
    await server.stop();
    await waitFor(
      () => container.read(connectionControllerProvider) is ConnectionFailed,
    );
    final error = (container.read(
      connectionControllerProvider,
    ) as ConnectionFailed).error;
    expect(
      (error as ModbusConnectionException).kind,
      ConnectionErrorKind.closed,
    );
  });

  test(
    'auto-reconnect restores the connection once the device is back',
    () async {
      final bank = SimulatorBank.demo();
      var server = await SimulatorTcpServer.start(bank: bank, port: 0);
      final port = server.port;
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container
          .read(connectionControllerProvider.notifier)
          .connect(
            profileFor(
              TcpConnectionConfig(host: '127.0.0.1', port: port),
              autoReconnect: true,
            ),
          );
      await server.stop();
      await waitFor(() {
        final s = container.read(connectionControllerProvider);
        return s is Connecting && s.attempt >= 1;
      });
      server = await SimulatorTcpServer.start(bank: bank, port: port);
      addTearDown(server.stop);
      await waitFor(
        () => container.read(connectionControllerProvider) is Connected,
        maxMs: 8000,
      );
      expect(
        await container.read(activeClientProvider)!.readHoldingRegisters(25, 1),
        [0x1234],
      );
    },
  );

  test('disconnect during auto-reconnect stops retrying', () async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    final container = createTestContainer();
    addTearDown(container.dispose);
    final controller = container.read(connectionControllerProvider.notifier);
    await controller.connect(
      profileFor(
        TcpConnectionConfig(host: '127.0.0.1', port: server.port),
        autoReconnect: true,
      ),
    );
    await server.stop();
    await waitFor(
      () => container.read(connectionControllerProvider) is Connecting,
    );
    await controller.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(container.read(connectionControllerProvider), isA<Disconnected>());
  });
}
