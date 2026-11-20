import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_history_settings.dart';
import 'package:modbus_explorer/shared/collections/ring_buffer.dart';

@immutable
final class MqttMessageLog {
  const new({
    required this.entries,
    required this.total,
    required this.capacity,
    this.paused = false,
  });

  /// Oldest first; bounded by [capacity].
  final List<MqttLogEntry> entries;

  /// All entries since the last clear, including dropped ones.
  final int total;
  final int capacity;
  final bool paused;

  /// Only the messages (sent and received).
  Iterable<MqttMessageRecord> get messages =>
      entries.whereType<MqttLogMessage>().map((m) => m.record);
}

/// Ring buffer of messages and connection events. Incoming entries are
/// batched and handed to the UI at most every [flushInterval].
final class MqttMessageLogController extends Notifier<MqttMessageLog> {
  static const flushInterval = Duration(milliseconds: 150);

  late RingBuffer<MqttLogEntry> _buffer;
  final _pending = <MqttLogEntry>[];
  Timer? _flush;
  bool _paused = false;

  @override
  MqttMessageLog build() {
    final capacity = ref.read(mqttHistorySettingsProvider).monitorSize;
    _buffer = RingBuffer(capacity);
    ref.listen(mqttHistorySettingsProvider.select((s) => s.monitorSize), (
      _,
      size,
    ) {
      _buffer = _buffer.resized(size);
      _emit();
    });
    final controller = ref.watch(mqttConnectionControllerProvider.notifier);
    final subscription = controller.log.listen(_onEntry);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _flush?.cancel();
    });
    return MqttMessageLog(entries: const [], total: 0, capacity: capacity);
  }

  void _onEntry(MqttLogEntry entry) {
    if (_paused) return;
    _pending.add(entry);
    _flush ??= Timer(flushInterval, _publish);
  }

  void _publish() {
    _flush = null;
    if (_pending.isEmpty) return;
    _buffer.addAll(_pending);
    _pending.clear();
    _emit();
  }

  void _emit() => state = MqttMessageLog(
    entries: List.unmodifiable(_buffer),
    total: _buffer.totalAdded,
    capacity: _buffer.capacity,
    paused: _paused,
  );

  void setPaused({required bool paused}) {
    _paused = paused;
    _emit();
  }

  void clear() {
    _pending.clear();
    _buffer = RingBuffer(_buffer.capacity);
    _emit();
  }
}

final mqttMessageLogControllerProvider =
    NotifierProvider<MqttMessageLogController, MqttMessageLog>(
      MqttMessageLogController.new,
    );

/// The monitor's filter.
final class MonitorFilterController extends Notifier<MonitorFilter> {
  @override
  MonitorFilter build() => const MonitorFilter();

  void update(MonitorFilter Function(MonitorFilter current) change) =>
      state = change(state);
}

final monitorFilterProvider =
    NotifierProvider<MonitorFilterController, MonitorFilter>(
      MonitorFilterController.new,
    );

/// Log entries passing the filter (newest last).
final filteredLogProvider = Provider<List<MqttLogEntry>>((ref) {
  final log = ref.watch(mqttMessageLogControllerProvider);
  final filter = ref.watch(monitorFilterProvider);
  if (!filter.isActive) return log.entries;
  return log.entries.where(filter.matcher()).toList();
});
