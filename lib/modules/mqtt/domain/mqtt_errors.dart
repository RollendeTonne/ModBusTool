/// Why a connection failed or dropped, independent of the MQTT package.
enum MqttFailureKind {
  /// Broker answered CONNACK with an error code ([MqttConnectFailure.code]).
  refused,

  /// Host not found, connection refused, network unreachable.
  network,

  /// Certificate rejected or TLS handshake failed.
  tls,
  timeout,

  /// Broker closed the connection (e.g. keep-alive, takeover by same ID).
  connectionLost,
  unknown,
}

final class MqttConnectFailure implements Exception {
  const new(this.kind, {this.code, this.detail});

  final MqttFailureKind kind;

  /// CONNACK return code (3.1.1: 1–5) or reason code (5: 0x80–0x9F).
  final int? code;

  /// Technical message for the details line.
  final String? detail;

  @override
  String toString() =>
      'MqttConnectFailure($kind${code == null ? '' : ', code $code'}'
      '${detail == null ? '' : ': $detail'})';
}

/// Reasons of a refused CONNECT, unified over 3.1.1 return codes and MQTT 5
/// reason codes so the UI needs one text per reason.
enum ConnackReason {
  unacceptableProtocolVersion,
  clientIdRejected,
  serverUnavailable,
  badCredentials,
  notAuthorized,
  unspecifiedError,
  malformedPacket,
  protocolError,
  implementationSpecificError,
  serverBusy,
  banned,
  badAuthenticationMethod,
  topicNameInvalid,
  packetTooLarge,
  quotaExceeded,
  payloadFormatInvalid,
  retainNotSupported,
  qosNotSupported,
  useAnotherServer,
  serverMoved,
  connectionRateExceeded,
  unknown,
}

/// MQTT 3.1.1 §3.2.2.3.
ConnackReason connackReasonV311(int code) => switch (code) {
  1 => ConnackReason.unacceptableProtocolVersion,
  2 => ConnackReason.clientIdRejected,
  3 => ConnackReason.serverUnavailable,
  4 => ConnackReason.badCredentials,
  5 => ConnackReason.notAuthorized,
  _ => ConnackReason.unknown,
};

/// MQTT 5 §3.2.2.2.
ConnackReason connackReasonV5(int code) => switch (code) {
  0x80 => ConnackReason.unspecifiedError,
  0x81 => ConnackReason.malformedPacket,
  0x82 => ConnackReason.protocolError,
  0x83 => ConnackReason.implementationSpecificError,
  0x84 => ConnackReason.unacceptableProtocolVersion,
  0x85 => ConnackReason.clientIdRejected,
  0x86 => ConnackReason.badCredentials,
  0x87 => ConnackReason.notAuthorized,
  0x88 => ConnackReason.serverUnavailable,
  0x89 => ConnackReason.serverBusy,
  0x8A => ConnackReason.banned,
  0x8C => ConnackReason.badAuthenticationMethod,
  0x90 => ConnackReason.topicNameInvalid,
  0x95 => ConnackReason.packetTooLarge,
  0x97 => ConnackReason.quotaExceeded,
  0x99 => ConnackReason.payloadFormatInvalid,
  0x9A => ConnackReason.retainNotSupported,
  0x9B => ConnackReason.qosNotSupported,
  0x9C => ConnackReason.useAnotherServer,
  0x9D => ConnackReason.serverMoved,
  0x9F => ConnackReason.connectionRateExceeded,
  _ => ConnackReason.unknown,
};
