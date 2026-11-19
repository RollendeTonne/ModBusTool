import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';
import 'package:modbus_explorer/features/network_scan/presentation/network_scan_controller.dart';

import '../../helpers/fake_files.dart';
import '../../helpers/pump_app.dart';

final scannedRanges = <String>[];

NetworkScanner fakeScanner() => NetworkScanner(
  portProbe: (ip, port, _) async {
    if ('$ip' == '192.168.50.10' && (port == 502 || port == 80)) {
      return PortState.open;
    }
    if ('$ip' == '192.168.50.20' && port == 22) return PortState.open;
    // A routed device (outside the local /24).
    if ('$ip' == '10.100.0.24' && port == 502) return PortState.open;
    return PortState.filtered;
  },
  modbusProbe: (ip, port, _) async => '$ip' == '192.168.50.10'
      ? ModbusIdentity(port: port, vendor: 'ACME', product: 'PLC-7')
      : null,
  hostnameLookup: (ip, _) async =>
      '$ip' == '192.168.50.10' ? 'plc7.local' : null,
  arpReader: () async => {
    Ipv4.parse('192.168.50.10'): '00:1D:9C:AA:BB:CC',
    Ipv4.parse('192.168.50.30'): '00:1D:9C:00:00:30',
  },
  localAddresses: () async => [
    (interface: 'en0', address: Ipv4.parse('192.168.50.5')),
  ],
);

Future<FakeFileExchange> openNetworkTab(WidgetTester tester) async {
  final files = FakeFileExchange();
  await tester.pumpModbusApp(
    size: const Size(1600, 1100),
    overrides: [
      networkScannerProvider.overrideWithValue(fakeScanner()),
      localAddressesProvider.overrideWith(
        (ref) async => [
          (interface: 'en0', address: Ipv4.parse('192.168.50.5')),
        ],
      ),
      fileExchangeProvider.overrideWithValue(files),
      // Widget tests run as Android, which has no ARP access.
      platformCapabilitiesProvider.overrideWithValue(
        PlatformCapabilities.forPlatform(TargetPlatform.macOS),
      ),
    ],
  );
  await tester.tapNavigation('Tools');
  await tester.tap(find.text('Network'));
  await tester.pumpAndSettle();
  return files;
}

Future<void> runScan(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('network.start')));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('range is suggested from the local interface', (tester) async {
    await openNetworkTab(tester);
    final range = tester.widget<TextField>(
      find.byKey(const Key('network.range')),
    );
    expect(range.controller!.text, '192.168.50.0/24');
    expect(find.text('en0 · 192.168.50.5'), findsOneWidget);
    expect(
      find.textContaining('Only scan networks you are permitted'),
      findsOne,
    );
  });

  testWidgets('scan lists hosts with name, MAC, ports and Modbus identity', (
    tester,
  ) async {
    await openNetworkTab(tester);
    await runScan(tester);

    expect(find.textContaining('3 hosts · 1 with Modbus'), findsOneWidget);
    final plc = find.byKey(const ValueKey('network.host.192.168.50.10'));
    for (final text in [
      'plc7.local',
      '00:1D:9C:AA:BB:CC',
      '80 HTTP',
      '502 Modbus',
      'Modbus on port 502 · ACME PLC-7',
    ]) {
      expect(
        find.descendant(of: plc, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(
      find.descendant(of: plc, matching: find.text('Connect')),
      findsOneWidget,
    );

    // Silent host known only from the ARP cache.
    final silent = find.byKey(const ValueKey('network.host.192.168.50.30'));
    expect(
      find.descendant(
        of: silent,
        matching: find.textContaining('no open ports'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: silent, matching: find.text('Connect')),
      findsNothing,
    );
  });

  testWidgets('filter, export and input validation', (tester) async {
    final files = await openNetworkTab(tester);
    await runScan(tester);

    await tester.tap(find.byKey(const Key('network.onlyModbus')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('network.host.192.168.50.20')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('network.host.192.168.50.10')), findsOne);

    await tester.tap(find.byKey(const Key('network.export')));
    await tester.pumpAndSettle();
    final csv = files.saved.single.content.split('\n');
    expect(csv.first, 'ip;hostname;mac;open_ports;modbus_port;modbus_device');
    expect(
      csv,
      contains(
        '192.168.50.10;plc7.local;00:1D:9C:AA:BB:CC;80 502;502;ACME PLC-7',
      ),
    );

    await tester.enterText(
      find.byKey(const Key('network.range')),
      '10.0.0.0/16',
    );
    await tester.tap(find.byKey(const Key('network.start')));
    await tester.pumpAndSettle();
    expect(find.text('At most 4096 addresses per scan'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('network.range')),
      '10.0.0.0/24',
    );
    await tester.enterText(find.byKey(const Key('network.ports')), 'http');
    await tester.tap(find.byKey(const Key('network.start')));
    await tester.pumpAndSettle();
    expect(find.text('Ports: Invalid value'), findsOneWidget);
  });

  testWidgets('without ARP access the MAC column is hidden', (tester) async {
    await tester.pumpModbusApp(
      size: const Size(1600, 1100),
      overrides: [
        networkScannerProvider.overrideWithValue(fakeScanner()),
        localAddressesProvider.overrideWith((ref) async => const []),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(TargetPlatform.android),
        ),
      ],
    );
    await tester.tapNavigation('Tools');
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MAC addresses are not available'), findsOne);
    await tester.enterText(
      find.byKey(const Key('network.range')),
      '192.168.50.0/24',
    );
    await runScan(tester);
    expect(find.textContaining('2 hosts'), findsOneWidget);
    expect(find.text('MAC unknown'), findsNothing);
  });

  testWidgets('sandboxed macOS explains why MACs are missing', (tester) async {
    await tester.pumpModbusApp(
      size: const Size(1600, 1100),
      overrides: [
        networkScannerProvider.overrideWithValue(fakeScanner()),
        localAddressesProvider.overrideWith((ref) async => const []),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            TargetPlatform.macOS,
            isSandboxed: true,
          ),
        ),
      ],
    );
    await tester.tapNavigation('Tools');
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    expect(find.textContaining('macOS app sandbox blocks'), findsOneWidget);
  });

  testWidgets('empty ARP table with found hosts shows the permission hint', (
    tester,
  ) async {
    await tester.pumpModbusApp(
      size: const Size(1600, 1100),
      overrides: [
        networkScannerProvider.overrideWithValue(
          NetworkScanner(
            portProbe: (ip, port, _) async =>
                '$ip' == '192.168.50.10' ? PortState.open : PortState.filtered,
            modbusProbe: (_, _, _) async => null,
            hostnameLookup: (_, _) async => null,
            arpReader: () async => const {},
            localAddresses: () async => const [],
          ),
        ),
        localAddressesProvider.overrideWith(
          (ref) async => [
            (interface: 'en0', address: Ipv4.parse('192.168.50.5')),
          ],
        ),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(TargetPlatform.macOS),
        ),
      ],
    );
    await tester.tapNavigation('Tools');
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('network.range')),
      '192.168.50.0/24',
    );
    await runScan(tester);
    expect(find.byKey(const Key('network.arpEmpty')), findsOneWidget);
    expect(find.textContaining('Local Network'), findsOneWidget);
  });

  testWidgets('routed ranges explain that MACs cannot be determined', (
    tester,
  ) async {
    await openNetworkTab(tester); // local address 192.168.50.5
    await tester.enterText(
      find.byKey(const Key('network.range')),
      '10.100.0.24',
    );
    await runScan(tester);
    expect(find.byKey(const Key('network.routed')), findsOneWidget);
    expect(find.byKey(const Key('network.arpEmpty')), findsNothing);
  });
}
