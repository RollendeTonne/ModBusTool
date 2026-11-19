import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/channel/socket_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/connection_factory.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/data/codec/rtu_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_tcp_server.dart';
import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';

void main() {
  // Real loopback sockets; port 0 lets the OS choose a free port.
  group('SimulatorTcpServer', () {
    test('serves Modbus TCP over a real socket', () async {
      final server = await SimulatorTcpServer.start(
        bank: SimulatorBank.demo(),
        port: 0,
      );
      addTearDown(server.stop);
      final factory = ModbusConnectionFactory(
        serialPorts: const UnsupportedSerialPortService(),
        simulatorBank: SimulatorBank.demo,
      );
      final client = await factory.open(
        TcpConnectionConfig(host: '127.0.0.1', port: server.port),
      );
      addTearDown(client.close);
      expect(await client.readHoldingRegisters(DemoMap.bcd16, 1), [0x1234]);
      expect(server.connectionCount, 1);
    });

    test('serves RTU over TCP', () async {
      final server = await SimulatorTcpServer.start(
        bank: SimulatorBank.demo(),
        port: 0,
        framing: const RtuFraming(),
      );
      addTearDown(server.stop);
      final channel = await SocketChannel.connect('127.0.0.1', server.port);
      final client = ModbusClient(
        channel: channel,
        framing: const RtuFraming(),
      );
      addTearDown(client.close);
      expect(await client.readHoldingRegisters(DemoMap.int16, 1), [
        -1234 & 0xFFFF,
      ]);
    });

    test('stopping the server closes client connections', () async {
      final server = await SimulatorTcpServer.start(
        bank: SimulatorBank.demo(),
        port: 0,
      );
      final channel = await SocketChannel.connect('127.0.0.1', server.port);
      final client = ModbusClient(
        channel: channel,
        framing: const MbapFraming(),
      );
      await client.readHoldingRegisters(0, 1);
      await server.stop();
      await client.done.timeout(const Duration(seconds: 2));
      expect(client.isClosed, isTrue);
    });
  });

  test('connection refused yields a readable connection error', () async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    final port = server.port;
    await server.stop();
    await expectLater(
      SocketChannel.connect('127.0.0.1', port),
      throwsA(
        isA<ModbusConnectionException>().having(
          (e) => e.message,
          'message',
          contains('127.0.0.1:$port'),
        ),
      ),
    );
  });
}
