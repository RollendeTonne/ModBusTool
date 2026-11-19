import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';

final _random = Random.secure();

/// `pe-` + 12 random characters; brokers accept up to 23 for 3.1.1.
String generateClientId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final suffix = List.generate(
    12,
    (_) => chars[_random.nextInt(chars.length)],
  ).join();
  return 'pe-$suffix';
}

/// Server argument for the MQTT packages: host, or the URL for WebSockets.
String serverFor(MqttConnectionConfig config) {
  if (!config.transport.webSocket) return config.host;
  final scheme = config.transport == MqttTransport.wss ? 'wss' : 'ws';
  final path = config.webSocketPath.startsWith('/')
      ? config.webSocketPath
      : '/${config.webSocketPath}';
  return '$scheme://${config.host}$path';
}

/// System roots plus the profile's CA and client certificate.
SecurityContext securityContextFor(
  MqttConnectionConfig config,
  MqttSecrets secrets,
) {
  final tls = config.tls;
  final context = SecurityContext(withTrustedRoots: true);
  if (tls.caCertificatePem case final ca? when ca.trim().isNotEmpty) {
    context.setTrustedCertificatesBytes(utf8.encode(ca));
  }
  if (tls.clientCertificatePem case final cert? when cert.trim().isNotEmpty) {
    context.useCertificateChainBytes(utf8.encode(cert));
    if (secrets.clientKeyPem case final key? when key.trim().isNotEmpty) {
      context.usePrivateKeyBytes(
        utf8.encode(key),
        password: secrets.clientKeyPassword,
      );
    }
  }
  return context;
}

/// Maps exceptions thrown while connecting to a [MqttConnectFailure].
/// The MQTT packages often wrap socket/TLS errors in their own exception
/// with only a message, so the text is inspected as a fallback.
MqttConnectFailure failureFrom(Object error) {
  if (error is MqttConnectFailure) return error;
  final detail = '$error';
  final text = detail.toLowerCase();
  if (error is HandshakeException ||
      error is TlsException ||
      text.contains('handshake') ||
      text.contains('certificate') ||
      text.contains('tlsexception')) {
    return MqttConnectFailure(MqttFailureKind.tls, detail: detail);
  }
  if (text.contains('timed out') || text.contains('timeout')) {
    return MqttConnectFailure(MqttFailureKind.timeout, detail: detail);
  }
  if (error is SocketException ||
      error is WebSocketException ||
      text.contains('socketexception') ||
      text.contains('could not be made') ||
      text.contains('failed host lookup') ||
      text.contains('connection refused')) {
    return MqttConnectFailure(MqttFailureKind.network, detail: detail);
  }
  return MqttConnectFailure(MqttFailureKind.unknown, detail: detail);
}
