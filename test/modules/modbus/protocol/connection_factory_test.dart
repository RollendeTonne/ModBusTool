import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/connection_factory.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/modules/modbus/simulator/domain/demo_devices.dart';

void main() {
  final bank = SimulatorBank.demo();
  final factory = ModbusConnectionFactory(
    serialPorts: const UnsupportedSerialPortService(),
    simulatorBank: () => bank,
  );

  for (final framing in SimulatorFraming.values) {
    test('simulator connection with $framing framing', () async {
      final client = await factory.open(
        SimulatorConnectionConfig(framing: framing, latency: Duration.zero),
      );
      addTearDown(client.close);
      expect(
        client.frameKind,
        framing == SimulatorFraming.tcp ? FrameKind.tcp : FrameKind.rtu,
      );
      expect(await client.readHoldingRegisters(DemoMap.bcd16, 1), [0x1234]);
    });
  }

  test('simulator connections share the device bank', () async {
    final first = await factory.open(const SimulatorConnectionConfig());
    await first.writeSingleRegister(900, 77);
    await first.close();
    final second = await factory.open(const SimulatorConnectionConfig());
    addTearDown(second.close);
    expect(await second.readHoldingRegisters(900, 1), [77]);
  });

  test('serial on unsupported platform fails with a connection error', () {
    expect(
      factory.open(
        const RtuConnectionConfig(
          serial: SerialSettings(portName: '/dev/ttyUSB0'),
        ),
      ),
      throwsA(isA<ModbusConnectionException>()),
    );
  });

  test('serial settings short description', () {
    expect(
      const SerialSettings(portName: 'COM3').shortDescription,
      '19200 8E1',
    );
    expect(
      const SerialSettings(
        portName: 'COM3',
        baudRate: 9600,
        parity: SerialParity.none,
      ).shortDescription,
      '9600 8N1',
    );
  });
}
