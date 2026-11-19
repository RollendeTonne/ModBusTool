import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/package_session_support.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:mqtt5_client/mqtt5_client.dart' as m;
import 'package:mqtt5_client/mqtt5_server_client.dart' as m;
import 'package:typed_data/typed_data.dart' as typed;

/// MQTT 5.0 via `mqtt5_client`, including publish properties.
final class Mqtt5Session implements MqttSession {
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
          ..autoReconnect = false
          ..logging(on: false);
    if (config.transport.secure) {
      client.securityContext = securityContextFor(config, _secrets);
      if (config.tls.acceptInvalidCertificates) {
        client.onBadCertificate = (_) => true;
      }
    }
    var message = m.MqttConnectMessage().withClientIdentifier(clientId);
    message = config.cleanStart
        ? message.startClean()
        : message.startSession(
            sessionExpiryInterval: config.sessionExpiry.inSeconds,
          );
    if (config.cleanStart && config.sessionExpiry > Duration.zero) {
      message = message.withSessionExpiryInterval(
        config.sessionExpiry.inSeconds,
      );
    }
    if (config.lastWill case final will?) {
      message = message
          .withWillTopic(will.topic)
          .withWillPayload(
            typed.Uint8Buffer()..addAll(utf8.encode(will.payload)),
          )
          .withWillQos(_qos(will.qos));
      if (will.retain) message = message.withWillRetain();
    }
    client
      ..connectionMessage = message
      ..onDisconnected = _onDisconnected;
    _client = client;

    try {
      await client
          .connect(
            config.username.isEmpty ? null : config.username,
            config.username.isEmpty ? null : _secrets.password,
          )
          .timeout(config.connectTimeout);
    } on TimeoutException {
      _closing = true;
      client.disconnect();
      throw const MqttConnectFailure(MqttFailureKind.timeout);
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
    final status = client.connectionStatus;
    final reason = status?.reasonCode;
    if (reason == null ||
        reason == m.MqttConnectReasonCode.success ||
        reason == m.MqttConnectReasonCode.notSet) {
      return null;
    }
    return MqttConnectFailure(
      MqttFailureKind.refused,
      code: m.MqttConnectReasonCodeSupport.mqttConnectReasonCode.asInt(reason),
      detail: status?.reasonString,
    );
  }

  void _onDisconnected() {
    if (_closing) return;
    _closing = true;
    _lost.add(const MqttConnectFailure(MqttFailureKind.connectionLost));
  }

  MqttMessageRecord _record(m.MqttPublishMessage publish) {
    final header = publish.header;
    final v = publish.variableHeader;
    final expiry = v?.messageExpiryInterval;
    final correlation = v?.correlationData;
    return MqttMessageRecord(
      direction: MqttDirection.received,
      topic: v?.topicName ?? '',
      payload: Uint8List.fromList(publish.payload.message ?? const []),
      timestamp: DateTime.now(),
      qos: MqttQosLevel.fromValue(header?.qos.index ?? 0),
      retain: header?.retain ?? false,
      duplicate: header?.duplicate ?? false,
      properties: v == null
          ? MqttMessageProperties.none
          : MqttMessageProperties(
              contentType: v.contentType,
              responseTopic: v.responseTopic,
              correlationData: correlation == null || correlation.isEmpty
                  ? null
                  : Uint8List.fromList(correlation),
              messageExpiry: expiry == null || expiry == 0
                  ? null
                  : Duration(seconds: expiry),
              topicAlias: v.topicAlias == 0 ? null : v.topicAlias,
              payloadIsUtf8: v.payloadFormatIndicator ? true : null,
              userProperties: [
                for (final p in v.userProperty)
                  (p.pairName ?? '', p.pairValue ?? ''),
              ],
              subscriptionIds: [for (final id in v.subscriptionIdentifier) ?id],
            ),
    );
  }

  static m.MqttQos _qos(MqttQosLevel qos) => switch (qos) {
    MqttQosLevel.atMostOnce => m.MqttQos.atMostOnce,
    MqttQosLevel.atLeastOnce => m.MqttQos.atLeastOnce,
    MqttQosLevel.exactlyOnce => m.MqttQos.exactlyOnce,
  };

  @override
  void subscribe(MqttSubscriptionSpec subscription) {
    final option = m.MqttSubscriptionOption()
      ..maximumQos = _qos(subscription.qos)
      ..noLocal = subscription.noLocal
      ..retainAsPublished = subscription.retainAsPublished
      ..retainHandling = switch (subscription.retainHandling) {
        MqttRetainHandling.sendOnSubscribe => m.MqttRetainHandling.sendRetained,
        MqttRetainHandling.sendIfNewSubscription =>
          m.MqttRetainHandling.sendRetainedOnlyIfNotExist,
        MqttRetainHandling.doNotSend => m.MqttRetainHandling.doNotSendRetained,
      };
    _client?.subscribeWithSubscription(
      m.MqttSubscription(m.MqttSubscriptionTopic(subscription.filter), option),
    );
  }

  @override
  void unsubscribe(String filter) => _client?.unsubscribeStringTopic(filter);

  @override
  MqttMessageRecord publish(MqttOutgoingMessage message) {
    final client = _client;
    if (client == null) throw StateError('not connected');
    final props = message.properties;
    final publish = m.MqttPublishMessage()
        .toTopic(message.topic)
        .withQos(_qos(message.qos))
        .publishData(typed.Uint8Buffer()..addAll(message.payload));
    if (props.contentType case final type? when type.isNotEmpty) {
      publish.withContentType(type);
    }
    if (props.responseTopic case final topic? when topic.isNotEmpty) {
      publish.withResponseTopic(topic);
    }
    if (props.correlationData case final data? when data.isNotEmpty) {
      publish.withResponseCorrelationdata(typed.Uint8Buffer()..addAll(data));
    }
    if (props.messageExpiry case final expiry?) {
      publish.withMessageExpiryInterval(expiry.inSeconds);
    }
    if (props.userProperties.isNotEmpty) {
      publish.withUserProperties([
        for (final (name, value) in props.userProperties)
          m.MqttUserProperty()
            ..pairName = name
            ..pairValue = value,
      ]);
    }
    if (props.payloadIsUtf8 ?? false) publish.withPayloadFormatIndicator(true);
    publish.setRetain(state: message.retain);
    client.publishUserMessage(publish);
    return MqttMessageRecord(
      direction: MqttDirection.sent,
      topic: message.topic,
      payload: message.payload,
      timestamp: DateTime.now(),
      qos: message.qos,
      retain: message.retain,
      properties: props,
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
