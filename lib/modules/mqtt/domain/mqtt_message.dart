import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';

enum MqttDirection { received, sent }

/// MQTT 5 publish properties (all optional; empty for 3.1.1).
@immutable
final class MqttMessageProperties {
  const new({
    this.contentType,
    this.responseTopic,
    this.correlationData,
    this.messageExpiry,
    this.topicAlias,
    this.payloadIsUtf8,
    this.userProperties = const [],
    this.subscriptionIds = const [],
  });

  final String? contentType;
  final String? responseTopic;
  final Uint8List? correlationData;
  final Duration? messageExpiry;
  final int? topicAlias;

  /// Payload format indicator: `true` = UTF-8 text declared by the sender.
  final bool? payloadIsUtf8;
  final List<(String, String)> userProperties;
  final List<int> subscriptionIds;

  static const none = MqttMessageProperties();

  bool get isEmpty =>
      contentType == null &&
      responseTopic == null &&
      correlationData == null &&
      messageExpiry == null &&
      topicAlias == null &&
      payloadIsUtf8 == null &&
      userProperties.isEmpty &&
      subscriptionIds.isEmpty;
}

/// One message as seen by the app, received or sent.
@immutable
final class MqttMessageRecord {
  const new({
    required this.direction,
    required this.topic,
    required this.payload,
    required this.timestamp,
    this.qos = MqttQosLevel.atMostOnce,
    this.retain = false,
    this.duplicate = false,
    this.properties = MqttMessageProperties.none,
  });

  final MqttDirection direction;
  final String topic;
  final Uint8List payload;
  final DateTime timestamp;
  final MqttQosLevel qos;
  final bool retain;
  final bool duplicate;
  final MqttMessageProperties properties;
}

/// What the user wants to publish.
@immutable
final class MqttOutgoingMessage {
  const new({
    required this.topic,
    required this.payload,
    this.qos = MqttQosLevel.atMostOnce,
    this.retain = false,
    this.properties = MqttMessageProperties.none,
  });

  final String topic;
  final Uint8List payload;
  final MqttQosLevel qos;
  final bool retain;
  final MqttMessageProperties properties;
}
