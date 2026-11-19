import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';

/// MQTT profile entry inside the shared profile document. Unknown enum
/// names fall back to defaults so newer files stay readable.
Map<String, Object?> mqttProfileToJson(MqttProfile p) {
  final c = p.config;
  return {
    'id': p.id,
    'name': p.name,
    'createdAt': p.createdAt.toUtc().toIso8601String(),
    if (p.lastUsedAt != null)
      'lastUsedAt': p.lastUsedAt!.toUtc().toIso8601String(),
    'autoReconnect': p.autoReconnect,
    'type': c.simulated ? 'simulator' : 'broker',
    'host': c.host,
    'port': c.port,
    'transport': c.transport.name,
    'webSocketPath': c.webSocketPath,
    'clientId': c.clientId,
    'username': c.username,
    'hasPassword': c.hasPassword,
    'cleanStart': c.cleanStart,
    'keepAliveS': c.keepAlive.inSeconds,
    'sessionExpiryS': c.sessionExpiry.inSeconds,
    'protocolVersion': c.protocolVersion.name,
    'connectTimeoutMs': c.connectTimeout.inMilliseconds,
    if (c.lastWill case final will?)
      'lastWill': {
        'topic': will.topic,
        'payload': will.payload,
        'qos': will.qos.value,
        'retain': will.retain,
      },
    'tls': {
      if (c.tls.caCertificatePem != null) 'caPem': c.tls.caCertificatePem,
      if (c.tls.clientCertificatePem != null)
        'clientCertPem': c.tls.clientCertificatePem,
      'acceptInvalid': c.tls.acceptInvalidCertificates,
    },
    'subscriptions': [
      for (final s in c.subscriptions)
        {
          'filter': s.filter,
          'qos': s.qos.value,
          'noLocal': s.noLocal,
          'retainAsPublished': s.retainAsPublished,
          'retainHandling': s.retainHandling.name,
          'enabled': s.enabled,
        },
    ],
  };
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

MqttProfile mqttProfileFromJson(Map<String, Object?> json) {
  final will = json['lastWill'] as Map<String, Object?>?;
  final tls = json['tls'] as Map<String, Object?>? ?? const {};
  final lastUsed = json['lastUsedAt'] as String?;
  return MqttProfile(
    id: json['id']! as String,
    name: json['name']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    lastUsedAt: lastUsed == null ? null : DateTime.parse(lastUsed),
    autoReconnect: json['autoReconnect'] as bool? ?? true,
    config: MqttConnectionConfig(
      simulated: json['type'] == 'simulator',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 1883,
      transport: _enum(
        MqttTransport.values,
        json['transport'],
        MqttTransport.tcp,
      ),
      webSocketPath: json['webSocketPath'] as String? ?? '/mqtt',
      clientId: json['clientId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      hasPassword: json['hasPassword'] as bool? ?? false,
      cleanStart: json['cleanStart'] as bool? ?? true,
      keepAlive: Duration(seconds: json['keepAliveS'] as int? ?? 60),
      sessionExpiry: Duration(seconds: json['sessionExpiryS'] as int? ?? 0),
      protocolVersion: _enum(
        MqttProtocolVersion.values,
        json['protocolVersion'],
        MqttProtocolVersion.v311,
      ),
      connectTimeout: Duration(
        milliseconds: json['connectTimeoutMs'] as int? ?? 5000,
      ),
      lastWill: will == null
          ? null
          : MqttLastWill(
              topic: will['topic']! as String,
              payload: will['payload'] as String? ?? '',
              qos: MqttQosLevel.fromValue(will['qos'] as int? ?? 0),
              retain: will['retain'] as bool? ?? false,
            ),
      tls: MqttTlsSettings(
        caCertificatePem: tls['caPem'] as String?,
        clientCertificatePem: tls['clientCertPem'] as String?,
        acceptInvalidCertificates: tls['acceptInvalid'] as bool? ?? false,
      ),
      subscriptions: [
        for (final s in json['subscriptions'] as List? ?? const [])
          if (s is Map<String, Object?>)
            MqttSubscriptionSpec(
              filter: s['filter']! as String,
              qos: MqttQosLevel.fromValue(s['qos'] as int? ?? 0),
              noLocal: s['noLocal'] as bool? ?? false,
              retainAsPublished: s['retainAsPublished'] as bool? ?? false,
              retainHandling: _enum(
                MqttRetainHandling.values,
                s['retainHandling'],
                MqttRetainHandling.sendOnSubscribe,
              ),
              enabled: s['enabled'] as bool? ?? true,
            ),
      ],
    ),
  );
}
