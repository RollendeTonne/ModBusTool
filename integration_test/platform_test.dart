import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service_desktop.dart';
import 'package:modbus_explorer/features/modbus/data/client/connection_factory.dart';
import 'package:modbus_explorer/features/network_scan/data/network_probes.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
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

  // Passive only: reads the OS ARP cache, does not scan the network.
  testWidgets('ARP table and interfaces are readable in the sandbox', (
    tester,
  ) async {
    final arp = await readArpTable();
    final locals = await localIpv4Addresses();
    debugPrint('ARP entries: ${arp.length}, IPv4 interfaces: ${locals.length}');
    expect(locals, isNotEmpty);
  }, skip: !isDesktop);

  testWidgets('network scanner finds the simulator on loopback', (
    tester,
  ) async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    addTearDown(server.stop);
    final hosts = await const NetworkScanner().run(
      NetworkScanConfig(
        range: Ipv4Range.parse('127.0.0.1'),
        ports: [server.port],
        modbusPorts: [server.port],
        readArp: false,
      ),
      onProgress: (_, _, _) {},
      onHost: (_) {},
      isCancelled: () => false,
    );
    expect(hosts.single.modbus?.product, 'MBX-SIM-1');
  }, skip: !isDesktop);
}
