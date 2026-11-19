import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/network_scan/data/network_probes.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';

@immutable
final class NetworkScanState {
  const new({
    this.isRunning = false,
    this.phase = ScanPhase.ports,
    this.done = 0,
    this.total = 0,
    this.hosts = const [],
    this.startedAt,
    this.finishedAt,
    this.cancelled = false,
    this.error,
    this.arpEmpty = false,
  });

  final bool isRunning;
  final ScanPhase phase;
  final int done;
  final int total;

  /// Sorted by address.
  final List<HostResult> hosts;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool cancelled;
  final Object? error;

  /// The ARP cache was read but returned nothing – on macOS typically
  /// missing "Local Network" permission.
  final bool arpEmpty;

  double? get progress => total == 0 ? null : done / total;

  NetworkScanState copyWith({
    bool? isRunning,
    ScanPhase? phase,
    int? done,
    int? total,
    List<HostResult>? hosts,
    DateTime? finishedAt,
    bool? cancelled,
    Object? error,
    bool? arpEmpty,
  }) => NetworkScanState(
    isRunning: isRunning ?? this.isRunning,
    phase: phase ?? this.phase,
    done: done ?? this.done,
    total: total ?? this.total,
    hosts: hosts ?? this.hosts,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    cancelled: cancelled ?? this.cancelled,
    error: error ?? this.error,
    arpEmpty: arpEmpty ?? this.arpEmpty,
  );
}

final networkScannerProvider = Provider<NetworkScanner>(
  (ref) => const NetworkScanner(),
);

final localAddressesProvider =
    FutureProvider<List<({String interface, Ipv4 address})>>(
      (ref) => localIpv4Addresses(),
    );

final class NetworkScanController extends Notifier<NetworkScanState> {
  /// Keeps scans bounded (a /20 network); larger ranges are rarely useful
  /// and would take very long without ICMP.
  static const maxAddresses = 4096;

  int _generation = 0;
  final _pending = <Ipv4, HostResult>{};
  Timer? _flushTimer;

  @override
  NetworkScanState build() {
    ref.onDispose(() {
      _generation++;
      _flushTimer?.cancel();
    });
    return const NetworkScanState();
  }

  Future<void> start(NetworkScanConfig config) async {
    if (state.isRunning) return;
    if (config.range.length > maxAddresses) {
      throw ArgumentError('Range too large');
    }
    final generation = ++_generation;
    state = NetworkScanState(isRunning: true, startedAt: DateTime.now());
    try {
      final result = await ref
          .read(networkScannerProvider)
          .run(
            config,
            onProgress: (phase, done, total) {
              if (!_current(generation)) return;
              // Progress arrives per probe; batch it with host updates.
              _schedule(generation, phase: phase, done: done, total: total);
            },
            onArpRead: (entries) {
              if (_current(generation)) {
                state = state.copyWith(arpEmpty: entries == 0);
              }
            },
            onHost: (host) {
              if (!_current(generation)) return;
              _pending[host.address] = host;
              _schedule(generation);
            },
            isCancelled: () => !_current(generation),
          );
      if (!_current(generation)) return;
      _flushTimer?.cancel();
      _pending.clear();
      state = state.copyWith(
        isRunning: false,
        phase: ScanPhase.done,
        hosts: result,
        finishedAt: DateTime.now(),
      );
    } on Object catch (e) {
      if (!_current(generation)) return;
      state = state.copyWith(
        isRunning: false,
        error: e,
        finishedAt: DateTime.now(),
      );
    }
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  ScanPhase? _phase;
  int? _done;
  int? _total;

  void _schedule(int generation, {ScanPhase? phase, int? done, int? total}) {
    _phase = phase ?? _phase;
    _done = done ?? _done;
    _total = total ?? _total;
    _flushTimer ??= Timer(const Duration(milliseconds: 100), () {
      _flushTimer = null;
      if (!_current(generation)) return;
      final merged = {for (final h in state.hosts) h.address: h, ..._pending};
      _pending.clear();
      state = state.copyWith(
        phase: _phase,
        done: _done,
        total: _total,
        hosts: merged.values.toList()
          ..sort((a, b) => a.address.compareTo(b.address)),
      );
    });
  }

  void cancel() {
    if (!state.isRunning) return;
    _generation++;
    _flushTimer?.cancel();
    _flushTimer = null;
    final merged = {for (final h in state.hosts) h.address: h, ..._pending};
    _pending.clear();
    state = state.copyWith(
      isRunning: false,
      cancelled: true,
      finishedAt: DateTime.now(),
      hosts: merged.values.toList()
        ..sort((a, b) => a.address.compareTo(b.address)),
    );
  }
}

final networkScanControllerProvider =
    NotifierProvider<NetworkScanController, NetworkScanState>(
      NetworkScanController.new,
    );
