import 'dart:async';
import 'dart:typed_data';

import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/package_session_support.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:mqtt_client/mqtt_client.dart' as m;
import 'package:mqtt_client/mqtt_server_client.dart' as m;
import 'package:typed_data/typed_data.dart' as typed;

/// MQTT 3.1.1 via `mqtt_client`.
final class Mqtt311Session implements MqttSession {
  new(this._config, this._secrets)
    : clientId = _config.autoClientId
          ? generateClientId()
          : _config.clientId.trim();

  final MqttConnectionConfig _config;
  final MqttSecrets _secrets;
  @override
  final String clientId;

  m.MqttServerClient? _client;
  final _messages = StreamController<MqttMessageRecord>.broadcast();
  final _lost = StreamController<MqttConnectFailure>.broadcast();
  StreamSubscription<Object?>? _updates;
  bool _closing = false;

  @override
  Stream<MqttMessageRecord> get messages => _messages.stream;

  @override
  Stream<MqttConnectFailure> get connectionLost => _lost.stream;

  @override
  Future<void> connect() async {
    final config = _config;
    final client =
        m.MqttServerClient.withPort(
            serverFor(config),
            clientId,
            config.port,
            maxConnectionAttempts: 1,
          )
          ..useWebSocket = config.transport.webSocket
          ..secure = config.transport == MqttTransport.tls
          ..keepAlivePeriod = config.keepAlive.inSeconds
          ..connectTimeoutPeriod = config.connectTimeout.inMilliseconds
          ..autoReconnect = false
          ..logging(on: false)
          ..setProtocolV311();
    if (config.transport.secure) {
      client.securityContext = securityContextFor(config, _secrets);
      if (config.tls.acceptInvalidCertificates) {
        // Typed as Object: mqtt_client casts the callback to
        // `bool Function(Object)` internally (found by the live test).
        // ignore: avoid_types_on_closure_parameters
        client.onBadCertificate = (Object _) => true;
      }
    }
    var message = m.MqttConnectMessage().withClientIdentifier(clientId);
    if (config.cleanStart) message = message.startClean();
    if (config.lastWill case final will?) {
      message = message
          .withWillTopic(will.topic)
          .withWillMessage(will.payload)
          .withWillQos(_qos(will.qos));
      if (will.retain) message = message.withWillRetain();
    }
    client
      ..connectionMessage = message
      ..onDisconnected = _onDisconnected;
    _client = client;

    try {
      await client.connect(
        config.username.isEmpty ? null : config.username,
        config.username.isEmpty ? null : _secrets.password,
      );
    } on Object catch (e) {
      throw _refusal(client) ?? failureFrom(e);
    }
    if (client.connectionStatus?.state != m.MqttConnectionState.connected) {
      throw _refusal(client) ??
          const MqttConnectFailure(MqttFailureKind.unknown);
    }
    _updates = client.updates?.listen((batch) {
      for (final received in batch) {
        final publish = received.payload;
        if (publish is m.MqttPublishMessage) _messages.add(_record(publish));
      }
    });
  }

  static MqttConnectFailure? _refusal(m.MqttServerClient client) {
    final code = client.connectionStatus?.returnCode;
    if (code == null ||
        code == m.MqttConnectReturnCode.connectionAccepted ||
        code == m.MqttConnectReturnCode.noneSpecified) {
      return null;
    }
    // Enum order equals the wire values 0–5.
    return MqttConnectFailure(MqttFailureKind.refused, code: code.index);
  }

  void _onDisconnected() {
    if (_closing) return;
    _closing = true;
    _lost.add(const MqttConnectFailure(MqttFailureKind.connectionLost));
  }

  MqttMessageRecord _record(m.MqttPublishMessage publish) {
    final header = publish.header;
    return MqttMessageRecord(
      direction: MqttDirection.received,
      topic: publish.variableHeader?.topicName ?? '',
      payload: Uint8List.fromList(publish.payload.message),
      timestamp: DateTime.now(),
      qos: MqttQosLevel.fromValue(header?.qos.index ?? 0),
      retain: header?.retain ?? false,
      duplicate: header?.duplicate ?? false,
    );
  }

  static m.MqttQos _qos(MqttQosLevel qos) => switch (qos) {
    MqttQosLevel.atMostOnce => m.MqttQos.atMostOnce,
    MqttQosLevel.atLeastOnce => m.MqttQos.atLeastOnce,
    MqttQosLevel.exactlyOnce => m.MqttQos.exactlyOnce,
  };

  @override
  void subscribe(MqttSubscriptionSpec subscription) =>
      _client?.subscribe(subscription.filter, _qos(subscription.qos));

  @override
  void unsubscribe(String filter) => _client?.unsubscribe(filter);

  @override
  MqttMessageRecord publish(MqttOutgoingMessage message) {
    final client = _client;
    if (client == null) throw StateError('not connected');
    client.publishMessage(
      message.topic,
      _qos(message.qos),
      typed.Uint8Buffer()..addAll(message.payload),
      retain: message.retain,
    );
    return MqttMessageRecord(
      direction: MqttDirection.sent,
      topic: message.topic,
      payload: message.payload,
      timestamp: DateTime.now(),
      qos: message.qos,
      retain: message.retain,
    );
  }

  @override
  Future<void> disconnect() async {
    _closing = true;
    await _updates?.cancel();
    _client?.disconnect();
    // Not awaited: a broadcast controller's close() only completes once
    // the done event is delivered, which can't happen while one of its
    // own events (connectionLost) is still being handled.
    unawaited(_messages.close());
    unawaited(_lost.close());
  }
}
