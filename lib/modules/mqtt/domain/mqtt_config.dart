import 'package:meta/meta.dart';

/// Stored by [name]: never rename values.
enum MqttTransport {
  tcp(1883, secure: false, webSocket: false),
  tls(8883, secure: true, webSocket: false),
  ws(80, secure: false, webSocket: true),
  wss(443, secure: true, webSocket: true);

  new(this.defaultPort, {required this.secure, required this.webSocket});

  final int defaultPort;
  final bool secure;
  final bool webSocket;
}

enum MqttProtocolVersion { v311, v5 }

/// QoS 0/1/2; [value] is the wire value.
enum MqttQosLevel {
  atMostOnce(0),
  atLeastOnce(1),
  exactlyOnce(2);

  new(this.value);

  final int value;

  static MqttQosLevel fromValue(int value) =>
      values.firstWhere((q) => q.value == value, orElse: () => atMostOnce);
}

/// MQTT 5 retain handling of a subscription (wire values 0–2).
enum MqttRetainHandling { sendOnSubscribe, sendIfNewSubscription, doNotSend }

@immutable
final class MqttLastWill {
  const new({
    required this.topic,
    this.payload = '',
    this.qos = MqttQosLevel.atMostOnce,
    this.retain = false,
  });

  final String topic;
  final String payload;
  final MqttQosLevel qos;
  final bool retain;

  @override
  bool operator ==(Object other) =>
      other is MqttLastWill &&
      other.topic == topic &&
      other.payload == payload &&
      other.qos == qos &&
      other.retain == retain;

  @override
  int get hashCode => Object.hash(topic, payload, qos, retain);
}

/// Certificates are public and stored in the profile; the client's private
/// key and its password live in the secret store.
@immutable
final class MqttTlsSettings {
  const new({
    this.caCertificatePem,
    this.clientCertificatePem,
    this.acceptInvalidCertificates = false,
  });

  /// Own CA in addition to the system's trusted roots.
  final String? caCertificatePem;
  final String? clientCertificatePem;

  /// Skips certificate validation: only for test brokers.
  final bool acceptInvalidCertificates;

  MqttTlsSettings copyWith({
    String? Function()? caCertificatePem,
    String? Function()? clientCertificatePem,
    bool? acceptInvalidCertificates,
  }) => MqttTlsSettings(
    caCertificatePem: caCertificatePem != null
        ? caCertificatePem()
        : this.caCertificatePem,
    clientCertificatePem: clientCertificatePem != null
        ? clientCertificatePem()
        : this.clientCertificatePem,
    acceptInvalidCertificates:
        acceptInvalidCertificates ?? this.acceptInvalidCertificates,
  );

  @override
  bool operator ==(Object other) =>
      other is MqttTlsSettings &&
      other.caCertificatePem == caCertificatePem &&
      other.clientCertificatePem == clientCertificatePem &&
      other.acceptInvalidCertificates == acceptInvalidCertificates;

  @override
  int get hashCode => Object.hash(
    caCertificatePem,
    clientCertificatePem,
    acceptInvalidCertificates,
  );
}

@immutable
final class MqttSubscriptionSpec {
  const new({
    required this.filter,
    this.qos = MqttQosLevel.atMostOnce,
    this.noLocal = false,
    this.retainAsPublished = false,
    this.retainHandling = MqttRetainHandling.sendOnSubscribe,
    this.enabled = true,
  });

  final String filter;
  final MqttQosLevel qos;

  /// MQTT 5 options; ignored for 3.1.1.
  final bool noLocal;
  final bool retainAsPublished;
  final MqttRetainHandling retainHandling;

  /// Disabled subscriptions are kept in the profile but not subscribed.
  final bool enabled;

  MqttSubscriptionSpec copyWith({
    String? filter,
    MqttQosLevel? qos,
    bool? noLocal,
    bool? retainAsPublished,
    MqttRetainHandling? retainHandling,
    bool? enabled,
  }) => MqttSubscriptionSpec(
    filter: filter ?? this.filter,
    qos: qos ?? this.qos,
    noLocal: noLocal ?? this.noLocal,
    retainAsPublished: retainAsPublished ?? this.retainAsPublished,
    retainHandling: retainHandling ?? this.retainHandling,
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      other is MqttSubscriptionSpec &&
      other.filter == filter &&
      other.qos == qos &&
      other.noLocal == noLocal &&
      other.retainAsPublished == retainAsPublished &&
      other.retainHandling == retainHandling &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(
    filter,
    qos,
    noLocal,
    retainAsPublished,
    retainHandling,
    enabled,
  );
}

/// Everything needed to connect to a broker except secrets.
@immutable
final class MqttConnectionConfig {
  const new({
    required this.host,
    this.port = 1883,
    this.transport = MqttTransport.tcp,
    this.webSocketPath = '/mqtt',
    this.clientId = '',
    this.username = '',
    this.hasPassword = false,
    this.cleanStart = true,
    this.keepAlive = const Duration(seconds: 60),
    this.sessionExpiry = Duration.zero,
    this.protocolVersion = MqttProtocolVersion.v311,
    this.lastWill,
    this.tls = const MqttTlsSettings(),
    this.connectTimeout = const Duration(seconds: 5),
    this.subscriptions = const [],
    this.simulated = false,
  });

  final String host;
  final int port;
  final MqttTransport transport;
  final String webSocketPath;

  /// Empty = generate a random ID on every connect.
  final String clientId;
  final String username;

  /// The password itself is in the secret store under the profile ID.
  final bool hasPassword;
  final bool cleanStart;
  final Duration keepAlive;

  /// MQTT 5 only; zero = session ends with the connection.
  final Duration sessionExpiry;
  final MqttProtocolVersion protocolVersion;
  final MqttLastWill? lastWill;
  final MqttTlsSettings tls;
  final Duration connectTimeout;
  final List<MqttSubscriptionSpec> subscriptions;

  /// Built-in demo broker instead of the network (tests, demo profile).
  final bool simulated;

  bool get autoClientId => clientId.trim().isEmpty;

  /// `host:port` or the WebSocket URL.
  String get endpoint => transport.webSocket
      ? '${transport == MqttTransport.wss ? 'wss' : 'ws'}://$host:$port'
            '${webSocketPath.startsWith('/') ? '' : '/'}$webSocketPath'
      : '$host:$port';

  MqttConnectionConfig copyWith({
    String? host,
    int? port,
    MqttTransport? transport,
    String? webSocketPath,
    String? clientId,
    String? username,
    bool? hasPassword,
    bool? cleanStart,
    Duration? keepAlive,
    Duration? sessionExpiry,
    MqttProtocolVersion? protocolVersion,
    MqttLastWill? Function()? lastWill,
    MqttTlsSettings? tls,
    Duration? connectTimeout,
    List<MqttSubscriptionSpec>? subscriptions,
    bool? simulated,
  }) => MqttConnectionConfig(
    host: host ?? this.host,
    port: port ?? this.port,
    transport: transport ?? this.transport,
    webSocketPath: webSocketPath ?? this.webSocketPath,
    clientId: clientId ?? this.clientId,
    username: username ?? this.username,
    hasPassword: hasPassword ?? this.hasPassword,
    cleanStart: cleanStart ?? this.cleanStart,
    keepAlive: keepAlive ?? this.keepAlive,
    sessionExpiry: sessionExpiry ?? this.sessionExpiry,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    lastWill: lastWill != null ? lastWill() : this.lastWill,
    tls: tls ?? this.tls,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    subscriptions: subscriptions ?? this.subscriptions,
    simulated: simulated ?? this.simulated,
  );

  @override
  bool operator ==(Object other) =>
      other is MqttConnectionConfig &&
      other.host == host &&
      other.port == port &&
      other.transport == transport &&
      other.webSocketPath == webSocketPath &&
      other.clientId == clientId &&
      other.username == username &&
      other.hasPassword == hasPassword &&
      other.cleanStart == cleanStart &&
      other.keepAlive == keepAlive &&
      other.sessionExpiry == sessionExpiry &&
      other.protocolVersion == protocolVersion &&
      other.lastWill == lastWill &&
      other.tls == tls &&
      other.connectTimeout == connectTimeout &&
      _listEquals(other.subscriptions, subscriptions) &&
      other.simulated == simulated;

  @override
  int get hashCode => Object.hash(
    host,
    port,
    transport,
    webSocketPath,
    clientId,
    username,
    hasPassword,
    cleanStart,
    keepAlive,
    sessionExpiry,
    protocolVersion,
    lastWill,
    tls,
    connectTimeout,
    Object.hashAll(subscriptions),
    simulated,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

@immutable
final class MqttProfile {
  const new({
    required this.id,
    required this.name,
    required this.config,
    required this.createdAt,
    this.lastUsedAt,
    this.autoReconnect = true,
  });

  final String id;
  final String name;
  final MqttConnectionConfig config;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool autoReconnect;

  MqttProfile copyWith({
    String? name,
    MqttConnectionConfig? config,
    DateTime? lastUsedAt,
    bool? autoReconnect,
  }) => MqttProfile(
    id: id,
    name: name ?? this.name,
    config: config ?? this.config,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    autoReconnect: autoReconnect ?? this.autoReconnect,
  );

  @override
  bool operator ==(Object other) =>
      other is MqttProfile &&
      other.id == id &&
      other.name == name &&
      other.config == config &&
      other.createdAt == createdAt &&
      other.lastUsedAt == lastUsedAt &&
      other.autoReconnect == autoReconnect;

  @override
  int get hashCode =>
      Object.hash(id, name, config, createdAt, lastUsedAt, autoReconnect);
}
