import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/monitor/domain/communication_statistics.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/frame_event.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_client.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_transaction.dart';

@immutable
final class CommunicationLogState {
  const new({
    this.frames = const [],
    this.transactions = const {},
    this.paused = false,
    this.notRecorded = 0,
  });

  /// Oldest first, capped at [CommunicationLogController.maxFrames].
  final List<FrameEvent> frames;

  /// By transaction number, for latency/result of a frame.
  final Map<int, ModbusTransaction> transactions;
  final bool paused;

  /// Frames dropped while paused.
  final int notRecorded;
}

/// Records frames and transactions of the active connection for the
/// monitor. UI updates are batched so polling at high rates doesn't
/// rebuild the list for every single frame.
final class CommunicationLogController extends Notifier<CommunicationLogState> {
  static const maxFrames = 5000;
  static const maxTransactions = 2500;
  static const flushInterval = Duration(milliseconds: 100);

  StreamSubscription<FrameEvent>? _frameSub;
  StreamSubscription<ModbusTransaction>? _transactionSub;
  final _pendingFrames = <FrameEvent>[];
  final _pendingTransactions = <ModbusTransaction>[];
  int _pendingDropped = 0;
  Timer? _flushTimer;

  @override
  CommunicationLogState build() {
    ref
      ..listen(
        activeClientProvider,
        (_, client) => _attach(client),
        fireImmediately: true,
      )
      ..onDispose(() {
        _flushTimer?.cancel();
        unawaited(_frameSub?.cancel());
        unawaited(_transactionSub?.cancel());
      });
    return const CommunicationLogState();
  }

  void _attach(ModbusClient? client) {
    unawaited(_frameSub?.cancel());
    unawaited(_transactionSub?.cancel());
    _frameSub = client?.frames.listen(_onFrame);
    _transactionSub = client?.transactions.listen(_onTransaction);
  }

  void _onFrame(FrameEvent frame) {
    if (state.paused) {
      _pendingDropped++;
    } else {
      _pendingFrames.add(frame);
    }
    _scheduleFlush();
  }

  void _onTransaction(ModbusTransaction transaction) {
    if (!state.paused) _pendingTransactions.add(transaction);
    _scheduleFlush();
  }

  void _scheduleFlush() => _flushTimer ??= Timer(flushInterval, flush);

  /// Applies buffered events; public for tests.
  @visibleForTesting
  void flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (!ref.mounted) return;
    if (_pendingFrames.isEmpty &&
        _pendingTransactions.isEmpty &&
        _pendingDropped == 0) {
      return;
    }
    final frames = [...state.frames, ..._pendingFrames];
    final transactions = {
      ...state.transactions,
      for (final t in _pendingTransactions) t.number: t,
    };
    while (transactions.length > maxTransactions) {
      transactions.remove(transactions.keys.first);
    }
    state = CommunicationLogState(
      frames: frames.length > maxFrames
          ? frames.sublist(frames.length - maxFrames)
          : frames,
      transactions: transactions,
      paused: state.paused,
      notRecorded: state.notRecorded + _pendingDropped,
    );
    _pendingFrames.clear();
    _pendingTransactions.clear();
    _pendingDropped = 0;
  }

  void setPaused({required bool paused}) {
    flush();
    state = CommunicationLogState(
      frames: state.frames,
      transactions: state.transactions,
      paused: paused,
      // The counter describes the current pause only.
    );
  }

  void clear() {
    _pendingFrames.clear();
    _pendingTransactions.clear();
    _pendingDropped = 0;
    state = CommunicationLogState(paused: state.paused);
  }
}

final communicationLogControllerProvider =
    NotifierProvider<CommunicationLogController, CommunicationLogState>(
      CommunicationLogController.new,
    );

/// Counts every transaction of the session, independent of the log's
/// pause/clear and buffer limits.
final class StatisticsController extends Notifier<CommunicationStatistics> {
  StreamSubscription<ModbusTransaction>? _subscription;

  @override
  CommunicationStatistics build() {
    ref
      ..listen(activeClientProvider, (_, client) {
        unawaited(_subscription?.cancel());
        _subscription = client?.transactions.listen(
          (t) => state = state.add(t),
        );
      }, fireImmediately: true)
      ..onDispose(() => unawaited(_subscription?.cancel()));
    return CommunicationStatistics(since: DateTime.now());
  }

  void reset() => state = CommunicationStatistics(since: DateTime.now());
}

final statisticsControllerProvider =
    NotifierProvider<StatisticsController, CommunicationStatistics>(
      StatisticsController.new,
    );
