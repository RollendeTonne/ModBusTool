import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/network_scan/data/network_probes.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_tcp_server.dart';

const timeout = Duration(milliseconds: 300);
final localhost = Ipv4.parse('127.0.0.1');

void main() {
  group('probes against real sockets', () {
    test('open, closed and filtered ports', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((s) => s.destroy());
      expect(await probePort(localhost, server.port, timeout), PortState.open);

      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final closedPort = closed.port;
      await closed.close();
      expect(await probePort(localhost, closedPort, timeout), PortState.closed);

      // TEST-NET-1 (RFC 5737) is never routed.
      expect(
        await probePort(
          Ipv4.parse('192.0.2.1'),
          502,
          const Duration(milliseconds: 150),
        ),
        PortState.filtered,
      );
    });

    test('Modbus probe identifies the simulator', () async {
      final server = await SimulatorTcpServer.start(
        bank: SimulatorBank.demo(),
        port: 0,
      );
      addTearDown(server.stop);
      final identity = await probeModbus(localhost, server.port, timeout);
      expect(identity, isNotNull);
      expect(identity!.vendor, 'Modbus Explorer');
      expect(identity.product, 'MBX-SIM-1');
      expect(identity.summary, 'Modbus Explorer MBX-SIM-1 1.0');
    });

    test('Modbus probe rejects a non-Modbus service', () async {
      // Accepts connections but never answers, like a web server waiting
      // for a request.
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      server.listen(sockets.add);
      addTearDown(() async {
        for (final s in sockets) {
          s.destroy();
        }
        await server.close();
      });
      expect(
        await probeModbus(
          localhost,
          server.port,
          const Duration(milliseconds: 50),
        ),
        isNull,
      );
    });

    test('reverse lookup of localhost and local addresses', () async {
      expect(
        await reverseLookup(localhost, const Duration(seconds: 2)),
        isNotNull,
      );
      expect(await localIpv4Addresses(), isA<List<Object>>());
    });
  });

  group('NetworkScanner with fakes', () {
    final range = Ipv4Range.parse('10.0.0.1-5');

    NetworkScanner fakeScanner({Duration delay = Duration.zero}) =>
        NetworkScanner(
          portProbe: (ip, port, _) async {
            await Future<void>.delayed(delay);
            if ('$ip' == '10.0.0.2' && port == 502) return PortState.open;
            if ('$ip' == '10.0.0.2' && port == 22) return PortState.closed;
            if ('$ip' == '10.0.0.3') return PortState.closed;
            return PortState.filtered;
          },
          modbusProbe: (ip, port, _) async =>
              ModbusIdentity(port: port, vendor: 'ACME', product: 'PLC-1'),
          hostnameLookup: (ip, _) async =>
              '$ip' == '10.0.0.2' ? 'plc.local' : null,
          arpReader: () async => {
            Ipv4.parse('10.0.0.2'): '00:1D:9C:00:00:02',
            Ipv4.parse('10.0.0.4'): '00:1D:9C:00:00:04', // silent host
            Ipv4.parse('10.0.0.99'): '00:1D:9C:00:00:99', // out of range
          },
          localAddresses: () async => [
            (interface: 'en0', address: Ipv4.parse('10.0.0.3')),
          ],
        );

    test(
      'combines ports, ARP, Modbus identity, names and local flag',
      () async {
        final phases = <ScanPhase>[];
        final hosts = await fakeScanner().run(
          NetworkScanConfig(
            range: range,
            ports: const [22, 502],
            modbusPorts: const [502],
          ),
          onProgress: (phase, done, total) {
            if (phases.isEmpty || phases.last != phase) phases.add(phase);
          },
          onHost: (_) {},
          isCancelled: () => false,
        );
        expect(hosts.map((h) => '${h.address}'), [
          '10.0.0.2',
          '10.0.0.3',
          '10.0.0.4',
        ]);
        final plc = hosts[0];
        expect(plc.openPorts, [502]);
        expect(plc.mac, '00:1D:9C:00:00:02');
        expect(plc.hostname, 'plc.local');
        expect(plc.modbus!.summary, 'ACME PLC-1');
        expect(hosts[1].isLocal, isTrue);
        expect(hosts[1].openPorts, isEmpty);
        expect(hosts[2].mac, '00:1D:9C:00:00:04');
        expect(hosts[2].openPorts, isEmpty);
        expect(phases, [
          ScanPhase.ports,
          ScanPhase.arp,
          ScanPhase.modbus,
          ScanPhase.hostnames,
          ScanPhase.done,
        ]);
      },
    );

    test('ARP and host names can be skipped', () async {
      final hosts = await fakeScanner().run(
        NetworkScanConfig(
          range: range,
          ports: const [502],
          modbusPorts: const [],
          readArp: false,
          resolveHostnames: false,
        ),
        onProgress: (_, _, _) {},
        onHost: (_) {},
        isCancelled: () => false,
      );
      expect(hosts.map((h) => '${h.address}'), ['10.0.0.2', '10.0.0.3']);
      expect(hosts.first.hostname, isNull);
      expect(hosts.first.modbus, isNull);
    });

    test('cancellation stops the scan early', () async {
      var cancelled = false;
      var probes = 0;
      final scanner = NetworkScanner(
        portProbe: (_, _, _) async {
          probes++;
          if (probes == 10) cancelled = true;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return PortState.filtered;
        },
        arpReader: () async => const {},
        localAddresses: () async => const [],
      );
      await scanner.run(
        NetworkScanConfig(
          range: Ipv4Range.parse('10.0.0.0/24'),
          ports: const [502],
          modbusPorts: const [],
          concurrency: 4,
        ),
        onProgress: (_, _, _) {},
        onHost: (_) {},
        isCancelled: () => cancelled,
      );
      expect(probes, lessThan(20));
    });
  });

  test('real scan of 127.0.0.1 finds the simulator as Modbus device', () async {
    final server = await SimulatorTcpServer.start(
      bank: SimulatorBank.demo(),
      port: 0,
    );
    addTearDown(server.stop);
    final hosts = await const NetworkScanner().run(
      NetworkScanConfig(
        range: Ipv4Range.parse('127.0.0.1'),
        ports: [server.port, 1],
        modbusPorts: [server.port],
        readArp: false,
      ),
      onProgress: (_, _, _) {},
      onHost: (_) {},
      isCancelled: () => false,
    );
    final host = hosts.single;
    expect(host.openPorts, [server.port]);
    expect(host.modbus?.product, 'MBX-SIM-1');
  });
}
