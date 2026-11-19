import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/read_plan.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_response.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';

@immutable
final class MapValue {
  const new({required this.value, required this.raw, this.changedAt});

  final InterpretedValue value;

  /// Raw registers (or 0/1 bits) the value was decoded from.
  final List<int> raw;
  final DateTime? changedAt;
}

@immutable
final class MapValuesState {
  const new({
    this.values = const {},
    this.errors = const {},
    this.readAt,
    this.isBusy = false,
    this.isPolling = false,
    this.lastError,
  });

  /// By entry ID.
  final Map<String, MapValue> values;

  /// Per-entry read errors (e.g. one block answered with an exception).
  final Map<String, Object> errors;
  final DateTime? readAt;
  final bool isBusy;
  final bool isPolling;
  final Object? lastError;

  MapValuesState copyWith({
    Map<String, MapValue>? values,
    Map<String, Object>? errors,
    DateTime? readAt,
    bool? isBusy,
    bool? isPolling,
    Object? Function()? lastError,
  }) => MapValuesState(
    values: values ?? this.values,
    errors: errors ?? this.errors,
    readAt: readAt ?? this.readAt,
    isBusy: isBusy ?? this.isBusy,
    isPolling: isPolling ?? this.isPolling,
    lastError: lastError != null ? lastError() : this.lastError,
  );
}

/// Reads all entries of the current register map with as few requests as
/// possible. A failing block only marks its own entries as failed.
final class MapValuesController extends Notifier<MapValuesState> {
  int _pollGeneration = 0;
  Timer? _pollTimer;

  @override
  MapValuesState build() {
    ref
      ..listen(activeClientProvider, (_, next) {
        if (next == null) stopPolling();
      })
      ..listen(currentProfileIdProvider, (previous, next) {
        if (previous != next) state = const MapValuesState();
      })
      ..onDispose(() => _pollTimer?.cancel());
    return const MapValuesState();
  }

  Future<bool> read() async {
    if (state.isBusy) return false;
    final client = ref.read(activeClientProvider);
    if (client == null) {
      state = state.copyWith(lastError: () => const NotConnectedError());
      return false;
    }
    final entries = ref.read(currentMapEntriesProvider);
    if (entries.isEmpty) return true;
    final unitId = ref.read(registersControllerProvider).query.unitId;
    state = state.copyWith(isBusy: true);

    final blocks = planReads([
      for (final e in entries) ReadRange(e.table, e.address, e.registerCount),
    ]);
    final data = <RegisterTable, Map<int, int>>{};
    final failed = <ReadRange, Object>{};
    for (final block in blocks) {
      try {
        final response = await client.execute(
          block.table.isBitTable
              ? ReadBitsRequest(
                  table: block.table,
                  address: block.start,
                  count: block.count,
                )
              : ReadRegistersRequest(
                  table: block.table,
                  address: block.start,
                  count: block.count,
                ),
          unitId: unitId,
        );
        final values = switch (response) {
          ReadRegistersResponse(:final values) => values,
          ReadBitsResponse(:final values) =>
            values.map((b) => b ? 1 : 0).toList(),
          _ => const <int>[],
        };
        final target = data.putIfAbsent(block.table, () => {});
        for (var i = 0; i < values.length; i++) {
          target[block.start + i] = values[i];
        }
      } on Object catch (e) {
        failed[block] = e;
      }
      if (!ref.mounted) return false;
    }

    final now = DateTime.now();
    final values = <String, MapValue>{};
    final errors = <String, Object>{};
    for (final entry in entries) {
      final block = failed.keys
          .where(
            (b) =>
                b.table == entry.table &&
                entry.address >= b.start &&
                entry.lastAddress <= b.end,
          )
          .firstOrNull;
      if (block != null) {
        errors[entry.id] = failed[block]!;
        continue;
      }
      final table = data[entry.table] ?? const {};
      final raw = [
        for (var a = entry.address; a <= entry.lastAddress; a++) table[a] ?? 0,
      ];
      final previous = state.values[entry.id];
      final changed = previous != null && !_sameValues(previous.raw, raw);
      values[entry.id] = MapValue(
        value: entry.decode(raw),
        raw: raw,
        changedAt: changed ? now : previous?.changedAt,
      );
    }
    state = state.copyWith(
      values: values,
      errors: errors,
      readAt: now,
      isBusy: false,
      lastError: () => failed.length == blocks.length && failed.isNotEmpty
          ? failed.values.first
          : null,
    );
    return failed.isEmpty;
  }

  static bool _sameValues(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void startPolling() {
    if (state.isPolling) return;
    if (ref.read(activeClientProvider) == null) {
      state = state.copyWith(lastError: () => const NotConnectedError());
      return;
    }
    final generation = ++_pollGeneration;
    state = state.copyWith(isPolling: true);
    unawaited(_pollOnce(generation));
  }

  void stopPolling() {
    _pollGeneration++;
    _pollTimer?.cancel();
    if (state.isPolling) state = state.copyWith(isPolling: false);
  }

  void togglePolling() => state.isPolling ? stopPolling() : startPolling();

  Future<void> _pollOnce(int generation) async {
    final started = Stopwatch()..start();
    await read();
    if (!ref.mounted || generation != _pollGeneration) return;
    final interval = ref.read(registersControllerProvider).pollInterval;
    final wait = interval - started.elapsed;
    _pollTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (generation == _pollGeneration) unawaited(_pollOnce(generation));
    });
  }

  void clearError() => state = state.copyWith(lastError: () => null);
}

final mapValuesControllerProvider =
    NotifierProvider<MapValuesController, MapValuesState>(
      MapValuesController.new,
    );
