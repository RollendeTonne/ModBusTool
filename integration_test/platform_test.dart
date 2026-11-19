import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service_desktop.dart';
import 'package:modbus_explorer/features/modbus/data/client/connection_factory.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_tcp_server.dart';
import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';
import 'package:path_provider/path_provider.dart';

/// Runs inside the real desktop app (sandbox, native plugins):
/// `flutter test integration_test -d macos`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final isDesktop = {
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  }.contains(defaultTargetPlatform);

  testWidgets('libserialport loads and enumerates ports', (tester) async {
    final ports = await const DesktopSerialPortService().listPorts();
    debugPrint('Serial ports: ${ports.map((p) => p.name).join(', ')}');
    expect(ports, isA<List<SerialPortInfo>>());
  }, skip: !isDesktop);

  testWidgets('simulator TCP server works inside the sandbox', (tester) async {
    final bank = SimulatorBank.demo();
    final server = await SimulatorTcpServer.start(bank: bank, port: 0);
    addTearDown(server.stop);
    final factory = ModbusConnectionFactory(
      serialPorts: const DesktopSerialPortService(),
      simulatorBank: () => bank,
    );
    final client = await factory.open(
      TcpConnectionConfig(host: '127.0.0.1', port: server.port),
    );
    addTearDown(client.close);
    expect(await client.readHoldingRegisters(DemoMap.bcd16, 1), [0x1234]);
  }, skip: !isDesktop);

  testWidgets('application support directory is writable', (tester) async {
    final dir = await getApplicationSupportDirectory();
    debugPrint('Application support: ${dir.path}');
    expect(dir.path, isNotEmpty);
  });
}
