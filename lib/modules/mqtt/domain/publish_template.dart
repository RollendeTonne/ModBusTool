import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';

/// A saved publish form: everything needed to send the same message again.
/// Payload stays as typed (with its format) so it can be edited.
@immutable
final class PublishTemplate {
  const new({
    required this.id,
    required this.name,
    required this.topic,
    this.payload = '',
    this.format = PayloadFormat.text,
    this.qos = MqttQosLevel.atMostOnce,
    this.retain = false,
    this.contentType = '',
    this.responseTopic = '',
    this.correlationData = '',
    this.messageExpiry = '',
    this.userProperties = '',
  });

  factory fromJson(Map<String, Object?> json) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    String text(String key) => json[key] as String? ?? '';
    return PublishTemplate(
      id: json['id']! as String,
      name: json['name']! as String,
      topic: json['topic']! as String,
      payload: text('payload'),
      format: pick(PayloadFormat.values, json['format'], PayloadFormat.text),
      qos: MqttQosLevel.fromValue(json['qos'] as int? ?? 0),
      retain: json['retain'] as bool? ?? false,
      contentType: text('contentType'),
      responseTopic: text('responseTopic'),
      correlationData: text('correlationData'),
      messageExpiry: text('messageExpiry'),
      userProperties: text('userProperties'),
    );
  }

  final String id;
  final String name;
  final String topic;
  final String payload;
  final PayloadFormat format;
  final MqttQosLevel qos;
  final bool retain;

  /// MQTT 5 fields as typed in the form.
  final String contentType;
  final String responseTopic;
  final String correlationData;
  final String messageExpiry;
  final String userProperties;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'topic': topic,
    'payload': payload,
    'format': format.name,
    'qos': qos.value,
    'retain': retain,
    if (contentType.isNotEmpty) 'contentType': contentType,
    if (responseTopic.isNotEmpty) 'responseTopic': responseTopic,
    if (correlationData.isNotEmpty) 'correlationData': correlationData,
    if (messageExpiry.isNotEmpty) 'messageExpiry': messageExpiry,
    if (userProperties.isNotEmpty) 'userProperties': userProperties,
  };

  PublishTemplate copyWith({String? id, String? name}) => PublishTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    topic: topic,
    payload: payload,
    format: format,
    qos: qos,
    retain: retain,
    contentType: contentType,
    responseTopic: responseTopic,
    correlationData: correlationData,
    messageExpiry: messageExpiry,
    userProperties: userProperties,
  );
}
