import 'dart:async';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/network_scan/data/network_probes.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';

enum ScanPhase { ports, arp, modbus, hostnames, done }

@immutable
final class NetworkScanConfig {
  const new({
    required this.range,
    required this.ports,
    required this.modbusPorts,
    this.timeout = const Duration(milliseconds: 300),
    this.concurrency = 96,
    this.resolveHostnames = true,
    this.readArp = true,
  });

  final Ipv4Range range;
  final List<int> ports;

  /// Open ports among these are verified with a Modbus request.
  final List<int> modbusPorts;
  final Duration timeout;

  /// Simultaneous connection attempts. macOS limits GUI apps to 256 open
  /// files by default, so stay well below.
  final int concurrency;
  final bool resolveHostnames;
  final bool readArp;
}

typedef PortProbe = Future<PortState> Function(Ipv4, int, Duration);
typedef ModbusProbe = Future<ModbusIdentity?> Function(Ipv4, int, Duration);
typedef HostnameLookup = Future<String?> Function(Ipv4, Duration);

/// Host discovery without ICMP (unavailable to apps): TCP connects to the
/// selected ports – a refusal also proves the host is alive – plus the
/// ARP cache, which lists hosts that answered ARP even if every port is
/// filtered.
final class NetworkScanner {
  const new({
    this.portProbe = probePort,
    this.modbusProbe = probeModbus,
    this.hostnameLookup = reverseLookup,
    this.arpReader = readArpTable,
    this.localAddresses = localIpv4Addresses,
  });

  final PortProbe portProbe;
  final ModbusProbe modbusProbe;
  final HostnameLookup hostnameLookup;
  final Future<Map<Ipv4, String>> Function() arpReader;
  final Future<List<({String interface, Ipv4 address})>> Function()
  localAddresses;

  static const _hostnameTimeout = Duration(milliseconds: 1500);

  Future<List<HostResult>> run(
    NetworkScanConfig config, {
    required void Function(ScanPhase phase, int done, int total) onProgress,
    required void Function(HostResult host) onHost,
    required bool Function() isCancelled,
  }) async {
    final hosts = <Ipv4, HostResult>{};
    void update(HostResult host) {
      hosts[host.address] = host;
      onHost(host);
    }

    // Phase 1: TCP probes over all (host, port) pairs.
    final tasks = [
      for (final address in config.range.addresses)
        for (final port in config.ports) (address, port),
    ];
    var done = 0;
    onProgress(ScanPhase.ports, 0, tasks.length);
    await _pool(tasks, config.concurrency, isCancelled, (task) async {
      final (address, port) = task;
      final state = await portProbe(address, port, config.timeout);
      done++;
      if (state != PortState.filtered) {
        final current = hosts[address] ?? HostResult(address: address);
        update(
          state == PortState.open
              ? current.copyWith(
                  openPorts: [...current.openPorts, port]..sort(),
                )
              : current,
        );
      }
      onProgress(ScanPhase.ports, done, tasks.length);
    });
    if (isCancelled()) return _sorted(hosts);

    // Phase 2: MAC addresses (and silent hosts) from the ARP cache, which
    // the probes above have just filled.
    if (config.readArp) {
      onProgress(ScanPhase.arp, 0, 1);
      final arp = await arpReader();
      for (final MapEntry(key: address, value: mac) in arp.entries) {
        if (!config.range.contains(address)) continue;
        update(
          (hosts[address] ?? HostResult(address: address)).copyWith(mac: mac),
        );
      }
    }

    final locals = {for (final l in await localAddresses()) l.address};
    for (final address in locals) {
      if (hosts[address] case final host?) update(host.copyWith(isLocal: true));
    }

    // Phase 3: verify Modbus on open Modbus ports.
    final modbusTasks = [
      for (final host in hosts.values)
        for (final port in host.openPorts)
          if (config.modbusPorts.contains(port)) (host.address, port),
    ];
    var modbusDone = 0;
    onProgress(ScanPhase.modbus, 0, modbusTasks.length);
    await _pool(modbusTasks, 8, isCancelled, (task) async {
      final (address, port) = task;
      final identity = await modbusProbe(address, port, config.timeout);
      modbusDone++;
      final host = hosts[address]!;
      // Prefer the identity with the most information (e.g. 502 over 1502).
      if (identity != null &&
          (host.modbus == null ||
              identity.summary.length > host.modbus!.summary.length)) {
        update(host.copyWith(modbus: identity));
      }
      onProgress(ScanPhase.modbus, modbusDone, modbusTasks.length);
    });
    if (isCancelled()) return _sorted(hosts);

    // Phase 4: host names.
    if (config.resolveHostnames) {
      final addresses = hosts.keys.toList();
      var namesDone = 0;
      onProgress(ScanPhase.hostnames, 0, addresses.length);
      await _pool(addresses, 16, isCancelled, (address) async {
        final name = await hostnameLookup(address, _hostnameTimeout);
        namesDone++;
        if (name != null) update(hosts[address]!.copyWith(hostname: name));
        onProgress(ScanPhase.hostnames, namesDone, addresses.length);
      });
    }
    onProgress(ScanPhase.done, 1, 1);
    return _sorted(hosts);
  }

  static List<HostResult> _sorted(Map<Ipv4, HostResult> hosts) =>
      hosts.values.toList()..sort((a, b) => a.address.compareTo(b.address));

  /// Runs [work] over [items] with at most [concurrency] in flight.
  static Future<void> _pool<T>(
    List<T> items,
    int concurrency,
    bool Function() isCancelled,
    Future<void> Function(T item) work,
  ) async {
    final iterator = items.iterator;
    Future<void> worker() async {
      while (!isCancelled() && iterator.moveNext()) {
        await work(iterator.current);
      }
    }

    await Future.wait([
      for (var i = 0; i < concurrency && i < items.length; i++) worker(),
    ]);
  }
}
