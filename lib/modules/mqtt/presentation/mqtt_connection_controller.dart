import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_repository.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session_factory.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profiles_controller.dart';

enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

@immutable
final class MqttConnectionState {
  const new({
    this.status = MqttConnectionStatus.disconnected,
    this.profile,
    this.clientId,
    this.failure,
    this.connectedAt,
    this.reconnectAttempt = 0,
    this.nextRetryAt,
  });

  final MqttConnectionStatus status;

  /// The profile of the current/last connection (live copy, subscriptions
  /// change while connected).
  final MqttProfile? profile;
  final String? clientId;
  final MqttConnectFailure? failure;
  final DateTime? connectedAt;
  final int reconnectAttempt;
  final DateTime? nextRetryAt;

  bool get isConnected => status == MqttConnectionStatus.connected;

  /// Connected, connecting or waiting to reconnect.
  bool get isActive =>
      status != MqttConnectionStatus.disconnected &&
      status != MqttConnectionStatus.error;
}

/// One broker connection at a time; reconnects with exponential back-off
/// (1 s … 30 s) when the connection drops and the profile allows it.
final class MqttConnectionController extends Notifier<MqttConnectionState> {
  static const maxBackoff = Duration(seconds: 30);

  MqttSession? _session;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _traffic = StreamController<MqttMessageRecord>.broadcast();
  final _log = StreamController<MqttLogEntry>.broadcast();
  Timer? _retryTimer;
  int _generation = 0;

  /// Every received and sent message (log, topic tree).
  Stream<MqttMessageRecord> get traffic => _traffic.stream;

  /// Messages plus connection events, for the monitor.
  Stream<MqttLogEntry> get log => _log.stream;

  /// Records an event in the monitor (also used by the replay).
  void logEvent(MqttEventKind kind, [String detail = '']) {
    if (!_log.isClosed) {
      _log.add(MqttLogEvent(kind, DateTime.now(), detail: detail));
    }
  }

  void _message(MqttMessageRecord record) {
    _traffic.add(record);
    if (!_log.isClosed) _log.add(MqttLogMessage(record));
  }

  static String _subscriptionText(MqttSubscriptionSpec s) => [
    s.filter,
    'QoS ${s.qos.value}',
    if (s.noLocal) 'noLocal',
    if (s.retainAsPublished) 'retainAsPublished',
    if (s.retainHandling != MqttRetainHandling.sendOnSubscribe)
      'retainHandling=${s.retainHandling.name}',
  ].join(' ');

  static String _failureText(MqttConnectFailure f) => [
    f.kind.name,
    if (f.code != null) 'code ${f.code}',
    if (f.detail != null) f.detail!,
  ].join(' · ');

  @override
  MqttConnectionState build() {
    ref.onDispose(() {
      _generation++;
      _retryTimer?.cancel();
      unawaited(_closeSession());
      unawaited(_traffic.close());
      unawaited(_log.close());
    });
    return const MqttConnectionState();
  }

  Future<void> connect(MqttProfile profile) async {
    await disconnect();
    final generation = ++_generation;
    state = MqttConnectionState(
      status: MqttConnectionStatus.connecting,
      profile: profile,
    );
    await _open(profile, generation, attempt: 0);
    if (ref.mounted && state.isConnected) {
      await ref
          .read(mqttProfilesControllerProvider.notifier)
          .markUsed(profile.id);
    }
  }

  Future<void> _open(
    MqttProfile profile,
    int generation, {
    required int attempt,
  }) async {
    final secrets = await ref
        .read(mqttProfileRepositoryProvider)
        .loadSecrets(profile.id);
    if (!ref.mounted || generation != _generation) return;
    final session = ref.read(mqttSessionFactoryProvider)(
      profile.config,
      secrets,
    );
    final c = profile.config;
    logEvent(
      MqttEventKind.connecting,
      '${c.simulated ? 'demo broker' : c.endpoint} '
      'MQTT ${c.protocolVersion.name}',
    );
    try {
      await session.connect();
    } on MqttConnectFailure catch (failure) {
      await session.disconnect();
      if (!ref.mounted || generation != _generation) return;
      logEvent(MqttEventKind.connectFailed, _failureText(failure));
      _onFailure(profile, failure, generation, attempt: attempt);
      return;
    }
    if (!ref.mounted || generation != _generation) {
      await session.disconnect();
      return;
    }
    _session = session;
    _subscriptions
      ..add(session.messages.listen(_message))
      ..add(
        session.connectionLost.listen(
          (failure) => _onConnectionLost(failure, generation),
        ),
      );
    logEvent(MqttEventKind.connected, 'client ID ${session.clientId}');
    for (final spec in profile.config.subscriptions) {
      if (spec.enabled) {
        session.subscribe(spec);
        logEvent(MqttEventKind.subscribe, _subscriptionText(spec));
      }
    }
    state = MqttConnectionState(
      status: MqttConnectionStatus.connected,
      profile: profile,
      clientId: session.clientId,
      connectedAt: DateTime.now(),
    );
  }

  void _onFailure(
    MqttProfile profile,
    MqttConnectFailure failure,
    int generation, {
    required int attempt,
  }) {
    // A refused CONNECT won't succeed by retrying (wrong password, banned).
    final retry = attempt > 0 && failure.kind != MqttFailureKind.refused;
    if (retry) {
      _scheduleRetry(profile, failure, generation, attempt: attempt);
    } else {
      state = MqttConnectionState(
        status: MqttConnectionStatus.error,
        profile: profile,
        failure: failure,
      );
    }
  }

  Future<void> _onConnectionLost(
    MqttConnectFailure failure,
    int generation,
  ) async {
    if (generation != _generation) return;
    final profile = state.profile;
    logEvent(MqttEventKind.connectionLost, _failureText(failure));
    await _closeSession();
    if (!ref.mounted || generation != _generation || profile == null) return;
    if (profile.autoReconnect) {
      _scheduleRetry(profile, failure, generation, attempt: 1);
    } else {
      state = MqttConnectionState(
        status: MqttConnectionStatus.error,
        profile: profile,
        failure: failure,
      );
    }
  }

  void _scheduleRetry(
    MqttProfile profile,
    MqttConnectFailure failure,
    int generation, {
    required int attempt,
  }) {
    final delay = backoffFor(attempt);
    logEvent(
      MqttEventKind.reconnectScheduled,
      'attempt $attempt in ${delay.inSeconds} s',
    );
    state = MqttConnectionState(
      status: MqttConnectionStatus.reconnecting,
      profile: profile,
      failure: failure,
      reconnectAttempt: attempt,
      nextRetryAt: DateTime.now().add(delay),
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (generation != _generation) return;
      unawaited(_open(profile, generation, attempt: attempt + 1));
    });
  }

  /// 1, 2, 4, 8, 16, 30, 30 … seconds.
  static Duration backoffFor(int attempt) => Duration(
    milliseconds: min(
      1000 * pow(2, max(0, attempt - 1)).toInt(),
      maxBackoff.inMilliseconds,
    ),
  );

  Future<void> disconnect() async {
    if (_session != null || state.isActive) logEvent(MqttEventKind.disconnect);
    _generation++;
    _retryTimer?.cancel();
    await _closeSession();
    if (!ref.mounted) return;
    if (state.status != MqttConnectionStatus.disconnected) {
      state = MqttConnectionState(profile: state.profile);
    }
  }

  Future<void> _closeSession() async {
    final session = _session;
    _session = null;
    // Cancelling takes effect immediately; awaiting the returned futures
    // would let a reconnect race with this close.
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _subscriptions.clear();
    await session?.disconnect();
  }

  /// Publishes and returns the sent record; throws [StateError] if not
  /// connected.
  MqttMessageRecord publish(MqttOutgoingMessage message) {
    final session = _session;
    if (session == null || !state.isConnected) {
      logEvent(MqttEventKind.publishFailed, '${message.topic}: not connected');
      throw StateError('not connected');
    }
    final MqttMessageRecord record;
    try {
      record = session.publish(message);
    } on Object catch (e) {
      logEvent(MqttEventKind.publishFailed, '${message.topic}: $e');
      rethrow;
    }
    _message(record);
    return record;
  }

  /// Adds or replaces (same filter) a subscription, live and in the profile.
  Future<void> putSubscription(
    MqttSubscriptionSpec spec, {
    String? replacing,
  }) async {
    final profile = state.profile;
    if (profile == null) return;
    final list = [
      for (final s in profile.config.subscriptions)
        if (s.filter != spec.filter && s.filter != replacing) s,
      spec,
    ];
    final old = profile.config.subscriptions
        .where((s) => s.filter == (replacing ?? spec.filter))
        .firstOrNull;
    final session = _session;
    if (session != null && state.isConnected) {
      if (old != null &&
          old.enabled &&
          (!spec.enabled || old.filter != spec.filter)) {
        session.unsubscribe(old.filter);
        logEvent(MqttEventKind.unsubscribe, old.filter);
      }
      if (spec.enabled) {
        session.subscribe(spec);
        logEvent(MqttEventKind.subscribe, _subscriptionText(spec));
      }
    }
    await _updateSubscriptions(profile, list);
  }

  Future<void> removeSubscription(String filter) async {
    final profile = state.profile;
    if (profile == null) return;
    if (state.isConnected && _session != null) {
      _session!.unsubscribe(filter);
      logEvent(MqttEventKind.unsubscribe, filter);
    }
    await _updateSubscriptions(profile, [
      for (final s in profile.config.subscriptions)
        if (s.filter != filter) s,
    ]);
  }

  Future<void> _updateSubscriptions(
    MqttProfile profile,
    List<MqttSubscriptionSpec> subscriptions,
  ) async {
    final updated = profile.copyWith(
      config: profile.config.copyWith(subscriptions: subscriptions),
    );
    state = MqttConnectionState(
      status: state.status,
      profile: updated,
      clientId: state.clientId,
      failure: state.failure,
      connectedAt: state.connectedAt,
      reconnectAttempt: state.reconnectAttempt,
      nextRetryAt: state.nextRetryAt,
    );
    // Persist without touching edits made to other fields meanwhile.
    final profiles = ref.read(mqttProfilesControllerProvider.notifier);
    final stored = profiles.byId(profile.id);
    if (stored != null) {
      await profiles.save(
        stored.copyWith(
          config: stored.config.copyWith(subscriptions: subscriptions),
        ),
      );
    }
  }

  /// For tests: the live session.
  @visibleForTesting
  MqttSession? get session => _session;
}

final mqttConnectionControllerProvider =
    NotifierProvider<MqttConnectionController, MqttConnectionState>(
      MqttConnectionController.new,
    );
