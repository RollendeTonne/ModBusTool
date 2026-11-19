import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/network_scan/data/active_network_detector.dart';
import 'package:modbus_explorer/features/network_scan/domain/active_network.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

({String interface, Ipv4 address}) iface(String name, String ip) =>
    (interface: name, address: Ipv4.parse(ip));

void main() {
  group('parsers', () {
    test('macOS default route', () {
      const out = '''
   route to: default
destination: default
       mask: default
    gateway: 10.0.0.1
  interface: en0
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
''';
      expect(parseMacDefaultRoute(out), 'en0');
      expect(
        parseMacDefaultRoute('route: writing to routing socket: not in table'),
        isNull,
      );
    });

    test('Linux /proc/net/route', () {
      const content = '''
Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT
docker0\t000011AC\t00000000\t0001\t0\t0\t0\t0000FFFF\t0\t0\t0
wlp2s0\t00000000\t0100A8C0\t0003\t0\t0\t600\t00000000\t0\t0\t0
wlp2s0\t0000A8C0\t00000000\t0001\t0\t0\t600\t00FFFFFF\t0\t0\t0
''';
      expect(parseLinuxDefaultRoute(content), 'wlp2s0');
      expect(parseLinuxDefaultRoute('Iface\tDestination\n'), isNull);
    });

    test('ifconfig hex netmask for the matching address only', () {
      const out = '''
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	inet6 fe80::1c%en0 prefixlen 64 secured scopeid 0xb
	inet 10.0.0.89 netmask 0xffffff00 broadcast 10.0.0.255
	inet 172.16.4.2 netmask 0xfffff000 broadcast 172.16.15.255
''';
      expect(parseIfconfigPrefix(out, Ipv4.parse('10.0.0.89')), 24);
      expect(parseIfconfigPrefix(out, Ipv4.parse('172.16.4.2')), 20);
      expect(parseIfconfigPrefix(out, Ipv4.parse('10.0.0.8')), isNull);
    });

    test('ip addr prefix', () {
      const out =
          '2: wlp2s0    inet 192.168.0.42/22 brd 192.168.3.255 scope global dynamic wlp2s0';
      expect(parseIpAddrPrefix(out, Ipv4.parse('192.168.0.42')), 22);
      expect(parseIpAddrPrefix(out, Ipv4.parse('192.168.0.4')), isNull);
    });

    test('mask to prefix', () {
      expect(prefixFromMask(0xFFFFFF00), 24);
      expect(prefixFromMask(0xFFFFFFFF), 32);
      expect(prefixFromMask(0), 0);
      expect(prefixFromMask(0xFF00FF00), isNull);
    });
  });

  group('chooseActiveInterface', () {
    final candidates = [
      iface('lo0', '127.0.0.1'),
      iface('utun4', '10.8.0.2'),
      iface('en7', '169.254.10.3'),
      iface('bridge100', '192.168.64.1'),
      iface('en0', '192.168.1.20'),
    ];

    test('prefers the default-route interface', () {
      expect(
        chooseActiveInterface(
          candidates,
          defaultRouteInterface: 'utun4',
        )!.interface,
        'utun4',
      );
    });

    test('falls back to physical adapters, skipping link-local', () {
      expect(chooseActiveInterface(candidates)!.interface, 'en0');
      expect(
        chooseActiveInterface(
          candidates,
          defaultRouteInterface: 'en9',
        )!.interface,
        'en0',
      );
    });

    test('Windows adapter names', () {
      expect(
        chooseActiveInterface([
          iface('vEthernet (WSL)', '172.20.0.1'),
          iface('Wi-Fi', '192.168.178.33'),
        ])!.interface,
        'Wi-Fi',
      );
    });

    test('nothing usable', () {
      expect(chooseActiveInterface([iface('lo0', '127.0.0.1')]), isNull);
      expect(chooseActiveInterface(const []), isNull);
    });
  });

  group('ActiveNetwork range', () {
    ActiveNetwork net(String ip, int? prefix) => ActiveNetwork(
      interface: 'en0',
      address: Ipv4.parse(ip),
      prefixLength: prefix,
    );

    test('uses the real subnet', () {
      expect(net('10.0.3.89', 23).cidr(), '10.0.2.0/23');
      expect(net('192.168.1.77', 26).cidr(), '192.168.1.64/26');
      expect(net('10.0.0.89', 24).scanRange().length, 254);
    });

    test('unknown mask or huge subnets fall back to /24', () {
      expect(net('10.0.3.89', null).cidr(), '10.0.3.0/24');
      expect(net('10.20.3.89', 8).cidr(), '10.20.3.0/24');
      expect(net('172.16.9.1', 20).cidr(), '172.16.0.0/20');
      expect(net('172.16.9.1', 19).cidr(), '172.16.9.0/24');
    });
  });

  group('ActiveNetworkDetector', () {
    test('macOS: default route + ifconfig', () async {
      final calls = <String>[];
      final detector = ActiveNetworkDetector(
        platform: TargetPlatform.macOS,
        listAddresses: () async => [
          iface('utun2', '100.64.1.2'),
          iface('en0', '10.0.0.89'),
        ],
        runProcess: (exe, args) async {
          calls.add('$exe ${args.join(' ')}');
          return ProcessResult(
            0,
            0,
            exe.endsWith('route')
                ? 'interface: en0\n'
                : 'inet 10.0.0.89 netmask 0xffffff00 broadcast 10.0.0.255',
            '',
          );
        },
      );
      final net = (await detector.detect())!;
      expect(net.interface, 'en0');
      expect(net.prefixLength, 24);
      expect(net.viaDefaultRoute, isTrue);
      expect(calls, ['/sbin/route -n get default', '/sbin/ifconfig en0']);
    });

    test('Linux: /proc/net/route + ip addr', () async {
      final detector = ActiveNetworkDetector(
        platform: TargetPlatform.linux,
        listAddresses: () async => [
          iface('docker0', '172.17.0.1'),
          iface('wlp2s0', '192.168.0.42'),
        ],
        readFile: (_) async =>
            'Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\n'
            'wlp2s0\t00000000\t0100A8C0\t0003\t0\t0\t600\t00000000\n',
        runProcess: (_, _) async => ProcessResult(
          0,
          0,
          '2: wlp2s0    inet 192.168.0.42/22 brd 192.168.3.255 scope global',
          '',
        ),
      );
      final net = (await detector.detect())!;
      expect(net.cidr(), '192.168.0.0/22');
    });

    test('failing tools degrade to heuristics and /24', () async {
      final detector = ActiveNetworkDetector(
        platform: TargetPlatform.macOS,
        listAddresses: () async => [
          iface('utun2', '100.64.1.2'),
          iface('en1', '192.168.5.9'),
        ],
        runProcess: (_, _) async => throw const ProcessException('route', []),
      );
      final net = (await detector.detect())!;
      expect(net.interface, 'en1');
      expect(net.viaDefaultRoute, isFalse);
      expect(net.prefixLength, isNull);
      expect(net.cidr(), '192.168.5.0/24');
    });

    test('mobile platforms use heuristics only, no processes', () async {
      final detector = ActiveNetworkDetector(
        platform: TargetPlatform.android,
        listAddresses: () async => [
          iface('rmnet_data0', '10.150.2.3'),
          iface('wlan0', '192.168.178.40'),
        ],
        runProcess: (_, _) => fail('no processes on Android'),
      );
      expect((await detector.detect())!.interface, 'wlan0');
    });
  });
}
