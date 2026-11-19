import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/package_session_support.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';

/// In-memory broker with a demo publisher: JSON, binary and retained
/// topics plus `$SYS`, so the MQTT module works without a network.
///
/// Username `denied` is refused with "bad username or password" to show
/// connection errors.
final class SimulatedBroker {
  new({this.interval = const Duration(seconds: 1)});

  static const deniedUser = 'denied';

  final Duration interval;
  final _retained = <String, MqttOutgoingMessage>{};
  final _sessions = <SimulatedMqttSession>{};
  final _started = DateTime.now();
  Timer? _timer;
  int _tick = 0;

  int get connectedClients => _sessions.length;

  void _attach(SimulatedMqttSession session) {
    if (_sessions.isEmpty) {
      _seedRetained();
      _timer = Timer.periodic(interval, (_) => _publishDemo());
    }
    _sessions.add(session);
  }

  void _detach(SimulatedMqttSession session) {
    _sessions.remove(session);
    if (_sessions.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _route(MqttOutgoingMessage message, {SimulatedMqttSession? from}) {
    if (message.retain) {
      if (message.payload.isEmpty) {
        _retained.remove(message.topic);
      } else {
        _retained[message.topic] = message;
      }
    }
    for (final session in [..._sessions]) {
      session._deliver(message, retainedReplay: false, from: from);
    }
  }

  void _replayRetained(
    SimulatedMqttSession session,
    MqttSubscriptionSpec subscription,
  ) {
    if (subscription.retainHandling == MqttRetainHandling.doNotSend) return;
    for (final message in _retained.values) {
      if (topicMatches(subscription.filter, message.topic)) {
        session._deliver(message, retainedReplay: true, only: subscription);
      }
    }
  }

  void _seedRetained() {
    if (_retained.isNotEmpty) return;
    void retain(String topic, String text, {String? contentType}) =>
        _retained[topic] = MqttOutgoingMessage(
          topic: topic,
          payload: _utf8(text),
          retain: true,
          properties: MqttMessageProperties(contentType: contentType),
        );
    retain('demo/plant/status', 'running');
    retain(
      'demo/plant/line1/info',
      jsonEncode({
        'vendor': 'ACME',
        'model': 'Line-1',
        'firmware': '2.4.1',
        'sensors': ['temperature', 'counter', 'power'],
      }),
      contentType: 'application/json',
    );
    retain(r'$SYS/broker/version', 'ProtocollExplorer demo broker 1.0');
  }

  void _publishDemo() {
    _tick++;
    final t = _tick.toDouble();
    void send(
      String topic,
      Uint8List payload, {
      bool retain = false,
      MqttMessageProperties properties = MqttMessageProperties.none,
    }) => _route(
      MqttOutgoingMessage(
        topic: topic,
        payload: payload,
        retain: retain,
        properties: properties,
      ),
    );

    send(
      'demo/plant/line1/temperature',
      _utf8(
        jsonEncode({
          'value': double.parse((21.5 + 3 * sin(t / 10)).toStringAsFixed(2)),
          'unit': '°C',
          'ts': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
      properties: const MqttMessageProperties(
        contentType: 'application/json',
        userProperties: [('site', 'demo'), ('line', '1')],
        payloadIsUtf8: true,
      ),
    );
    // UINT32 big endian.
    send(
      'demo/plant/line1/counter',
      Uint8List(4)..buffer.asByteData().setUint32(0, 100000 + _tick * 7),
    );
    // FLOAT32 big endian.
    send(
      'demo/plant/line1/power',
      Uint8List(4)
        ..buffer.asByteData().setFloat32(0, 4.2 + sin(t / 5).abs() * 1.3),
    );
    if (_tick % 5 == 0) {
      send(
        'demo/plant/line2/state',
        _utf8(_tick % 10 == 0 ? 'idle' : 'producing'),
        retain: true,
      );
    }
    for (final id in ['s1', 's2', 's3']) {
      send(
        'demo/sensors/$id/humidity',
        _utf8((45 + 10 * sin(t / 7 + id.codeUnitAt(1))).toStringAsFixed(1)),
      );
    }
    if (_tick % 10 == 0) {
      send(
        r'$SYS/broker/uptime',
        _utf8('${DateTime.now().difference(_started).inSeconds} seconds'),
        retain: true,
      );
      send(
        r'$SYS/broker/clients/connected',
        _utf8('$connectedClients'),
        retain: true,
      );
    }
  }

  static Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final class SimulatedMqttSession implements MqttSession {
  new(this._broker, this._config)
    : clientId = _config.autoClientId
          ? generateClientId()
          : _config.clientId.trim();

  final SimulatedBroker _broker;
  final MqttConnectionConfig _config;
  @override
  final String clientId;

  final _subscriptions = <String, MqttSubscriptionSpec>{};
  final _messages = StreamController<MqttMessageRecord>.broadcast();
  final _lost = StreamController<MqttConnectFailure>.broadcast();
  bool _connected = false;

  @override
  Stream<MqttMessageRecord> get messages => _messages.stream;

  @override
  Stream<MqttConnectFailure> get connectionLost => _lost.stream;

  @override
  Future<void> connect() async {
    if (_config.username == SimulatedBroker.deniedUser) {
      throw MqttConnectFailure(
        MqttFailureKind.refused,
        code: _config.protocolVersion == MqttProtocolVersion.v5 ? 0x86 : 4,
      );
    }
    _connected = true;
    _broker._attach(this);
  }

  /// Simulates the broker dropping the connection (tests).
  void simulateConnectionLoss() {
    if (!_connected) return;
    _connected = false;
    _broker._detach(this);
    _lost.add(const MqttConnectFailure(MqttFailureKind.connectionLost));
  }

  void _deliver(
    MqttOutgoingMessage message, {
    required bool retainedReplay,
    SimulatedMqttSession? from,
    MqttSubscriptionSpec? only,
  }) {
    if (!_connected) return;
    final matching = only != null
        ? [only]
        : _subscriptions.values
              .where((s) => topicMatches(s.filter, message.topic))
              .toList();
    if (matching.isEmpty) return;
    final v5 = _config.protocolVersion == MqttProtocolVersion.v5;
    if (v5 && from == this && matching.every((s) => s.noLocal)) return;
    // Highest granted QoS wins, capped by the published QoS.
    final granted = matching
        .map((s) => s.qos.value)
        .reduce(max)
        .clamp(0, message.qos.value);
    // Retain flag: set for replayed retained messages; for live ones only
    // with "retain as published" (MQTT 5).
    final retain =
        retainedReplay ||
        (v5 && message.retain && matching.any((s) => s.retainAsPublished));
    _messages.add(
      MqttMessageRecord(
        direction: MqttDirection.received,
        topic: message.topic,
        payload: message.payload,
        timestamp: DateTime.now(),
        qos: MqttQosLevel.fromValue(granted),
        retain: retain,
        properties: v5 ? message.properties : MqttMessageProperties.none,
      ),
    );
  }

  @override
  void subscribe(MqttSubscriptionSpec subscription) {
    if (!_connected) return;
    final existed = _subscriptions.containsKey(subscription.filter);
    _subscriptions[subscription.filter] = subscription;
    if (subscription.retainHandling ==
            MqttRetainHandling.sendIfNewSubscription &&
        existed) {
      return;
    }
    _broker._replayRetained(this, subscription);
  }

  @override
  void unsubscribe(String filter) => _subscriptions.remove(filter);

  @override
  MqttMessageRecord publish(MqttOutgoingMessage message) {
    if (!_connected) throw StateError('not connected');
    _broker._route(message, from: this);
    return MqttMessageRecord(
      direction: MqttDirection.sent,
      topic: message.topic,
      payload: message.payload,
      timestamp: DateTime.now(),
      qos: message.qos,
      retain: message.retain,
      properties: message.properties,
    );
  }

  @override
  Future<void> disconnect() async {
    if (_connected) _broker._detach(this);
    _connected = false;
    // Not awaited: a broadcast controller's close() only completes once
    // the done event is delivered, which can't happen while one of its
    // own events (connectionLost) is still being handled.
    unawaited(_messages.close());
    unawaited(_lost.close());
  }
}

final simulatedBrokerProvider = Provider<SimulatedBroker>((ref) {
  final broker = SimulatedBroker();
  ref.onDispose(broker.dispose);
  return broker;
});
