import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';

@immutable
final class ReplayState {
  const new({this.running = false, this.done = 0, this.total = 0, this.name});

  final bool running;
  final int done;
  final int total;
  final String? name;
}

/// Publishes a planned replay with its delays. Steps without delay are
/// sent in batches of [batchSize] per event-loop turn so "no pauses" does
/// not freeze the UI; progress updates are throttled the same way.
final class MqttReplayController extends Notifier<ReplayState> {
  static const batchSize = 100;

  Timer? _timer;
  List<ReplayStep> _steps = const [];
  int _index = 0;
  int _generation = 0;

  @override
  ReplayState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ReplayState();
  }

  MqttConnectionController get _connection =>
      ref.read(mqttConnectionControllerProvider.notifier);

  void start(List<ReplayStep> steps, {required String name}) {
    stop(silent: true);
    if (steps.isEmpty) return;
    _steps = steps;
    _index = 0;
    _generation++;
    state = ReplayState(running: true, total: steps.length, name: name);
    _connection.logEvent(
      MqttEventKind.replayStarted,
      '$name, ${steps.length} messages',
    );
    _schedule(_generation);
  }

  void _schedule(int generation) {
    if (_index >= _steps.length) {
      _finish();
      return;
    }
    _timer = Timer(_steps[_index].delay, () => _run(generation));
  }

  void _run(int generation) {
    if (generation != _generation) return;
    var sent = 0;
    do {
      try {
        _connection.publish(_steps[_index].message);
      } on Object {
        // Logged by the connection controller (not connected etc.).
        _finish(aborted: true);
        return;
      }
      _index++;
      sent++;
    } while (_index < _steps.length &&
        _steps[_index].delay == Duration.zero &&
        sent < batchSize);
    state = ReplayState(
      running: true,
      done: _index,
      total: _steps.length,
      name: state.name,
    );
    _schedule(generation);
  }

  void _finish({bool aborted = false}) {
    _timer?.cancel();
    _connection.logEvent(
      MqttEventKind.replayFinished,
      '${state.name}, $_index/${_steps.length}${aborted ? ', aborted' : ''}',
    );
    state = ReplayState(done: _index, total: _steps.length, name: state.name);
  }

  void stop({bool silent = false}) {
    if (!state.running) return;
    _generation++;
    if (silent) {
      _timer?.cancel();
      state = const ReplayState();
    } else {
      _finish(aborted: true);
    }
  }
}

final mqttReplayControllerProvider =
    NotifierProvider<MqttReplayController, ReplayState>(
      MqttReplayController.new,
    );
