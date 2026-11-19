import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/shared/collections/ring_buffer.dart';

@immutable
final class MqttMessageLog {
  const new({required this.messages, required this.total, this.paused = false});

  /// Oldest first; bounded by [MqttMessageLogController.capacity].
  final List<MqttMessageRecord> messages;

  /// All messages since the last clear, including dropped ones.
  final int total;
  final bool paused;
}

/// Ring buffer of recent traffic. Incoming messages are batched and
/// published to the UI at most every [flushInterval], so high message
/// rates cost one rebuild per interval instead of one per message.
final class MqttMessageLogController extends Notifier<MqttMessageLog> {
  static const capacity = 5000;
  static const flushInterval = Duration(milliseconds: 150);

  RingBuffer<MqttMessageRecord> _buffer = RingBuffer(capacity);
  final _pending = <MqttMessageRecord>[];
  Timer? _flush;
  bool _paused = false;

  @override
  MqttMessageLog build() {
    final controller = ref.watch(mqttConnectionControllerProvider.notifier);
    final subscription = controller.traffic.listen(_onMessage);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _flush?.cancel();
    });
    return const MqttMessageLog(messages: [], total: 0);
  }

  void _onMessage(MqttMessageRecord record) {
    if (_paused) return;
    _pending.add(record);
    _flush ??= Timer(flushInterval, _publish);
  }

  void _publish() {
    _flush = null;
    if (_pending.isEmpty) return;
    _buffer.addAll(_pending);
    _pending.clear();
    state = MqttMessageLog(
      messages: List.unmodifiable(_buffer),
      total: _buffer.totalAdded,
      paused: _paused,
    );
  }

  void setPaused({required bool paused}) {
    _paused = paused;
    state = MqttMessageLog(
      messages: state.messages,
      total: state.total,
      paused: paused,
    );
  }

  void clear() {
    _pending.clear();
    _buffer = RingBuffer(capacity);
    state = MqttMessageLog(messages: const [], total: 0, paused: _paused);
  }
}

final mqttMessageLogControllerProvider =
    NotifierProvider<MqttMessageLogController, MqttMessageLog>(
      MqttMessageLogController.new,
    );
