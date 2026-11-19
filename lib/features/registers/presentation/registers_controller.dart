import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/registers/domain/register_snapshot.dart';

/// Raised when an operation needs a connection and there is none.
final class NotConnectedError implements Exception {
  const new();
}

@immutable
final class RegisterQuery {
  const new({
    this.table = RegisterTable.holdingRegisters,
    this.address = 0,
    this.count = 10,
    this.unitId,
  });

  final RegisterTable table;

  /// Protocol (0-based) address.
  final int address;
  final int count;

  /// Overrides the profile's unit ID when set.
  final int? unitId;

  int get maxCount => table.isBitTable
      ? ModbusLimits.maxReadBits
      : ModbusLimits.maxReadRegisters;

  ModbusRequest toRequest() => table.isBitTable
      ? ReadBitsRequest(table: table, address: address, count: count)
      : ReadRegistersRequest(table: table, address: address, count: count);

  RegisterQuery copyWith({
    RegisterTable? table,
    int? address,
    int? count,
    int? Function()? unitId,
  }) => RegisterQuery(
    table: table ?? this.table,
    address: address ?? this.address,
    count: count ?? this.count,
    unitId: unitId != null ? unitId() : this.unitId,
  );

  @override
  bool operator ==(Object other) =>
      other is RegisterQuery &&
      other.table == table &&
      other.address == address &&
      other.count == count &&
      other.unitId == unitId;

  @override
  int get hashCode => Object.hash(table, address, count, unitId);
}

enum RegistersView { raw, map }

@immutable
final class RegistersState {
  const new({
    this.query = const RegisterQuery(),
    this.snapshot,
    this.isBusy = false,
    this.isPolling = false,
    this.pollInterval = const Duration(seconds: 1),
    this.lastError,
    this.readCount = 0,
    this.errorCount = 0,
    this.writeUnlocked = false,
    this.selectionStart,
    this.selectionEnd,
    this.view = RegistersView.raw,
  });

  final RegisterQuery query;
  final RegisterSnapshot? snapshot;
  final bool isBusy;
  final bool isPolling;
  final Duration pollInterval;
  final Object? lastError;
  final int readCount;
  final int errorCount;

  /// Session-level write protection; writes are blocked until unlocked.
  final bool writeUnlocked;

  /// Selected protocol address range (inclusive) for interpretation.
  final int? selectionStart;
  final int? selectionEnd;
  final RegistersView view;

  bool isSelected(int address) {
    final start = selectionStart;
    if (start == null) return false;
    return address >= start && address <= (selectionEnd ?? start);
  }

  RegistersState copyWith({
    RegisterQuery? query,
    RegisterSnapshot? Function()? snapshot,
    bool? isBusy,
    bool? isPolling,
    Duration? pollInterval,
    Object? Function()? lastError,
    int? readCount,
    int? errorCount,
    bool? writeUnlocked,
    (int?, int?)? selection,
    RegistersView? view,
  }) => RegistersState(
    query: query ?? this.query,
    snapshot: snapshot != null ? snapshot() : this.snapshot,
    isBusy: isBusy ?? this.isBusy,
    isPolling: isPolling ?? this.isPolling,
    pollInterval: pollInterval ?? this.pollInterval,
    lastError: lastError != null ? lastError() : this.lastError,
    readCount: readCount ?? this.readCount,
    errorCount: errorCount ?? this.errorCount,
    writeUnlocked: writeUnlocked ?? this.writeUnlocked,
    selectionStart: selection != null ? selection.$1 : selectionStart,
    selectionEnd: selection != null ? selection.$2 : selectionEnd,
    view: view ?? this.view,
  );
}

final class RegistersController extends Notifier<RegistersState> {
  static const minPollInterval = Duration(milliseconds: 50);

  int _pollGeneration = 0;
  Timer? _pollTimer;

  @override
  RegistersState build() {
    ref
      ..listen(activeClientProvider, (previous, next) {
        if (next == null) stopPolling();
      })
      ..onDispose(() => _pollTimer?.cancel());
    return const RegistersState();
  }

  ModbusClient? get _client => ref.read(activeClientProvider);

  void setQuery(RegisterQuery query) {
    final clamped = query.copyWith(count: query.count.clamp(1, query.maxCount));
    final tableChanged = clamped.table != state.query.table;
    state = state.copyWith(
      query: clamped,
      selection: tableChanged ? (null, null) : null,
    );
  }

  /// Selects [address]; with [extend] the range from the current anchor.
  void select(int address, {bool extend = false}) {
    final anchor = state.selectionStart;
    if (extend && anchor != null) {
      state = state.copyWith(
        selection: address < anchor ? (address, anchor) : (anchor, address),
      );
    } else {
      state = state.copyWith(selection: (address, address));
    }
  }

  void clearSelection() => state = state.copyWith(selection: (null, null));

  void setView(RegistersView view) => state = state.copyWith(view: view);

  void setPollInterval(Duration interval) => state = state.copyWith(
    pollInterval: interval < minPollInterval ? minPollInterval : interval,
  );

  void setWriteUnlocked({required bool unlocked}) =>
      state = state.copyWith(writeUnlocked: unlocked);

  void clearError() => state = state.copyWith(lastError: () => null);

  /// Reads the current query once. Returns `false` on error (see
  /// [RegistersState.lastError]).
  Future<bool> read() async {
    if (state.isBusy) return false;
    final client = _client;
    if (client == null) {
      state = state.copyWith(lastError: () => const NotConnectedError());
      return false;
    }
    final query = state.query;
    state = state.copyWith(isBusy: true);
    final watch = Stopwatch()..start();
    try {
      final response = await client.execute(
        query.toRequest(),
        unitId: query.unitId,
      );
      if (!ref.mounted) return false;
      final values = switch (response) {
        ReadRegistersResponse(:final values) => values,
        ReadBitsResponse(:final values) =>
          values.map((b) => b ? 1 : 0).toList(),
        _ => throw StateError('Unexpected response $response'),
      };
      final now = DateTime.now();
      final previous = state.snapshot;
      final snapshot = previous == null
          ? RegisterSnapshot.initial(
              table: query.table,
              start: query.address,
              values: values,
              readAt: now,
              latency: watch.elapsed,
            )
          : previous.next(
              values,
              now,
              table: query.table,
              start: query.address,
              latency: watch.elapsed,
            );
      state = state.copyWith(
        snapshot: () => snapshot,
        isBusy: false,
        lastError: () => null,
        readCount: state.readCount + 1,
      );
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isBusy: false,
        lastError: () => e,
        errorCount: state.errorCount + 1,
      );
      return false;
    }
  }

  void startPolling() {
    if (state.isPolling) return;
    if (_client == null) {
      state = state.copyWith(lastError: () => const NotConnectedError());
      return;
    }
    final generation = ++_pollGeneration;
    state = state.copyWith(isPolling: true, readCount: 0, errorCount: 0);
    unawaited(_pollOnce(generation));
  }

  void stopPolling() {
    _pollGeneration++;
    _pollTimer?.cancel();
    if (state.isPolling) state = state.copyWith(isPolling: false);
  }

  void togglePolling() => state.isPolling ? stopPolling() : startPolling();

  /// The interval is measured start-to-start; a slow response delays the
  /// next poll instead of piling up requests.
  Future<void> _pollOnce(int generation) async {
    final started = Stopwatch()..start();
    await read();
    if (!ref.mounted || generation != _pollGeneration) return;
    final wait = state.pollInterval - started.elapsed;
    _pollTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (generation == _pollGeneration) unawaited(_pollOnce(generation));
    });
  }

  /// Sends a write request. Throws on failure; on success the affected
  /// range is re-read if it is visible and polling is off.
  Future<void> write(ModbusRequest request) async {
    if (!request.isWrite) throw ArgumentError('Not a write request');
    if (!state.writeUnlocked) {
      throw StateError('Writing is locked');
    }
    final client = _client;
    if (client == null) throw const NotConnectedError();
    await client.execute(request, unitId: state.query.unitId);
    if (!ref.mounted) return;
    if (!state.isPolling && state.snapshot != null) {
      // Wait for an in-flight read to finish so the refresh isn't skipped.
      while (state.isBusy) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await read();
    }
  }
}

final registersControllerProvider =
    NotifierProvider<RegistersController, RegistersState>(
      RegistersController.new,
    );
