import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:modbus_explorer/features/network_scan/data/network_probes.dart';
import 'package:modbus_explorer/features/network_scan/domain/active_network.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

typedef ProcessRunner = Future<ProcessResult> Function(String, List<String>);

/// Determines the currently used network. Every step degrades gracefully:
/// no routing table → name heuristics, no netmask → /24.
final class ActiveNetworkDetector {
  new({
    this.listAddresses = localIpv4Addresses,
    this.runProcess = Process.run,
    Future<String> Function(String path)? readFile,
    TargetPlatform? platform,
  }) : _readFile = readFile ?? ((path) => File(path).readAsString()),
       _platform = platform ?? defaultTargetPlatform;

  final Future<List<({String interface, Ipv4 address})>> Function()
  listAddresses;
  final ProcessRunner runProcess;
  final Future<String> Function(String path) _readFile;
  final TargetPlatform _platform;

  Future<ActiveNetwork?> detect() async {
    final candidates = await listAddresses();
    final routeInterface = await _defaultRouteInterface();
    final chosen = chooseActiveInterface(
      candidates,
      defaultRouteInterface: routeInterface,
    );
    if (chosen == null) return null;
    return ActiveNetwork(
      interface: chosen.interface,
      address: chosen.address,
      prefixLength: await _prefix(chosen.interface, chosen.address),
      viaDefaultRoute: chosen.interface == routeInterface,
    );
  }

  Future<String?> _defaultRouteInterface() async {
    try {
      switch (_platform) {
        case TargetPlatform.macOS:
          final r = await runProcess('/sbin/route', ['-n', 'get', 'default']);
          return parseMacDefaultRoute(r.stdout as String);
        case TargetPlatform.linux:
          return parseLinuxDefaultRoute(await _readFile('/proc/net/route'));
        case TargetPlatform.windows ||
            TargetPlatform.android ||
            TargetPlatform.iOS ||
            TargetPlatform.fuchsia:
          return null;
      }
    } on Object {
      return null;
    }
  }

  Future<int?> _prefix(String interface, Ipv4 address) async {
    try {
      switch (_platform) {
        case TargetPlatform.macOS:
          final r = await runProcess('/sbin/ifconfig', [interface]);
          return parseIfconfigPrefix(r.stdout as String, address);
        case TargetPlatform.linux:
          final r = await runProcess('ip', [
            '-o',
            '-4',
            'addr',
            'show',
            'dev',
            interface,
          ]);
          return parseIpAddrPrefix(r.stdout as String, address);
        case TargetPlatform.windows ||
            TargetPlatform.android ||
            TargetPlatform.iOS ||
            TargetPlatform.fuchsia:
          return null;
      }
    } on Object {
      return null;
    }
  }
}
