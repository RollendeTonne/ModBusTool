import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_client.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_limits.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_response.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';

enum ScanMode { slaveIds, registers }

/// One responding unit ID or address.
@immutable
final class ScanHit {
  const new({required this.key, this.value, this.exceptionCode, this.latency});

  /// Unit ID (slave scan) or protocol address (register scan).
  final int key;

  /// Register value or 0/1 for bits; `null` for exception answers.
  final int? value;

  /// The device answered with this exception (still counts as present).
  final int? exceptionCode;
  final Duration? latency;
}

@immutable
final class ScanState {
  const new({
    this.mode = ScanMode.slaveIds,
    this.isRunning = false,
    this.done = 0,
    this.total = 0,
    this.hits = const [],
    this.startedAt,
    this.finishedAt,
    this.cancelled = false,
    this.error,
  });

  final ScanMode mode;
  final bool isRunning;
  final int done;
  final int total;
  final List<ScanHit> hits;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool cancelled;

  /// Fatal error that stopped the scan (e.g. connection lost).
  final Object? error;

  double get progress => total == 0 ? 0 : done / total;
}

final class ScannerController extends Notifier<ScanState> {
  int _generation = 0;

  @override
  ScanState build() {
    ref.listen(activeClientProvider, (_, client) {
      if (client == null && state.isRunning) cancel();
    });
    return const ScanState();
  }

  void cancel() {
    _generation++;
    if (state.isRunning) {
      state = ScanState(
        mode: state.mode,
        done: state.done,
        total: state.total,
        hits: state.hits,
        startedAt: state.startedAt,
        finishedAt: DateTime.now(),
        cancelled: true,
      );
    }
  }

  /// Probes unit IDs [from]..[to] with a 1-register read. Any answer –
  /// including an exception – means a device is present.
  Future<void> scanSlaves({
    required int from,
    required int to,
    required RegisterTable table,
    required int address,
    required Duration timeout,
  }) async {
    final ids = [
      for (var id = from; id <= to; id++)
        if (id != ModbusLimits.broadcastUnitId) id,
    ];
    final request = _readRequest(table, address, 1);
    await _run(ScanMode.slaveIds, ids.length, (client, generation) async {
      for (final id in ids) {
        if (generation != _generation) return;
        final hit = await _probe(
          () =>
              client.execute(request, unitId: id, timeout: timeout, retries: 0),
          key: id,
        );
        _advance(generation, hit);
      }
    });
  }

  /// Finds readable addresses in [from]..[to]. Reads blocks of [blockSize]
  /// first and falls back to single addresses where a block fails, so
  /// dense areas need few requests.
  Future<void> scanRegisters({
    required RegisterTable table,
    required int from,
    required int to,
    required Duration timeout,
    int blockSize = 10,
  }) async {
    final unitId = ref.read(registersControllerProvider).query.unitId;
    await _run(ScanMode.registers, to - from + 1, (client, generation) async {
      for (var start = from; start <= to; start += blockSize) {
        if (generation != _generation) return;
        final count = (to - start + 1).clamp(1, blockSize);
        final watch = Stopwatch()..start();
        List<int>? values;
        try {
          values = _values(
            await client.execute(
              _readRequest(table, start, count),
              unitId: unitId,
              timeout: timeout,
              retries: 0,
            ),
          );
        } on ModbusConnectionException {
          rethrow;
        } on ModbusError {
          values = null;
        }
        if (values != null) {
          for (var i = 0; i < values.length; i++) {
            _advance(
              generation,
              ScanHit(key: start + i, value: values[i], latency: watch.elapsed),
            );
          }
          continue;
        }
        if (count == 1) {
          _advance(generation, null);
          continue;
        }
        for (var address = start; address < start + count; address++) {
          if (generation != _generation) return;
          final hit = await _probe(
            () => client.execute(
              _readRequest(table, address, 1),
              unitId: unitId,
              timeout: timeout,
              retries: 0,
            ),
            key: address,
            // "Address does not exist" is the expected answer for gaps.
            ignoreException: ModbusExceptionCode.illegalDataAddress,
          );
          _advance(generation, hit);
        }
      }
    });
  }

  Future<void> _run(
    ScanMode mode,
    int total,
    Future<void> Function(ModbusClient client, int generation) body,
  ) async {
    if (state.isRunning) return;
    final client = ref.read(activeClientProvider);
    if (client == null) {
      state = ScanState(mode: mode, error: const NotConnectedError());
      return;
    }
    final generation = ++_generation;
    state = ScanState(
      mode: mode,
      isRunning: true,
      total: total,
      startedAt: DateTime.now(),
    );
    try {
      await body(client, generation);
      if (!ref.mounted || generation != _generation) return;
      state = _copy(isRunning: false, finishedAt: DateTime.now());
    } on Object catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = _copy(isRunning: false, finishedAt: DateTime.now(), error: e);
    }
  }

  Future<ScanHit?> _probe(
    Future<ModbusResponse> Function() send, {
    required int key,
    ModbusExceptionCode? ignoreException,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final values = _values(await send());
      return ScanHit(
        key: key,
        value: values.firstOrNull,
        latency: watch.elapsed,
      );
    } on ModbusDeviceException catch (e) {
      if (e.code != null && e.code == ignoreException) return null;
      return ScanHit(
        key: key,
        exceptionCode: e.exceptionCode,
        latency: watch.elapsed,
      );
    } on ModbusConnectionException {
      rethrow;
    } on ModbusError {
      return null;
    }
  }

  void _advance(int generation, ScanHit? hit) {
    if (!ref.mounted || generation != _generation) return;
    state = _copy(
      done: state.done + 1,
      hits: hit == null ? null : [...state.hits, hit],
    );
  }

  ScanState _copy({
    int? done,
    List<ScanHit>? hits,
    bool? isRunning,
    DateTime? finishedAt,
    Object? error,
  }) => ScanState(
    mode: state.mode,
    isRunning: isRunning ?? state.isRunning,
    done: done ?? state.done,
    total: state.total,
    hits: hits ?? state.hits,
    startedAt: state.startedAt,
    finishedAt: finishedAt ?? state.finishedAt,
    error: error ?? state.error,
  );

  static ModbusRequest _readRequest(
    RegisterTable table,
    int address,
    int count,
  ) => table.isBitTable
      ? ReadBitsRequest(table: table, address: address, count: count)
      : ReadRegistersRequest(table: table, address: address, count: count);

  static List<int> _values(ModbusResponse response) => switch (response) {
    ReadRegistersResponse(:final values) => values,
    ReadBitsResponse(:final values) => values.map((b) => b ? 1 : 0).toList(),
    _ => const [],
  };
}

final scannerControllerProvider =
    NotifierProvider<ScannerController, ScanState>(ScannerController.new);
