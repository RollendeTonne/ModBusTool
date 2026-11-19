import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';

/// Readable explanation of a connection failure, CONNACK codes in words.
String mqttFailureText(
  AppLocalizations l10n,
  MqttConnectFailure failure,
  MqttProtocolVersion version,
) => switch (failure.kind) {
  MqttFailureKind.refused => l10n.mqttFailRefused(
    connackReasonText(
      l10n,
      version == MqttProtocolVersion.v5
          ? connackReasonV5(failure.code ?? 0)
          : connackReasonV311(failure.code ?? 0),
    ),
    version == MqttProtocolVersion.v5
        ? '0x${(failure.code ?? 0).toRadixString(16).toUpperCase()}'
        : '${failure.code}',
  ),
  MqttFailureKind.network => l10n.mqttFailNetwork,
  MqttFailureKind.tls => l10n.mqttFailTls,
  MqttFailureKind.timeout => l10n.mqttFailTimeout,
  MqttFailureKind.connectionLost => l10n.mqttFailLost,
  MqttFailureKind.unknown => l10n.mqttFailUnknown,
};

String connackReasonText(AppLocalizations l10n, ConnackReason reason) =>
    switch (reason) {
      ConnackReason.unacceptableProtocolVersion => l10n.connackProtocolVersion,
      ConnackReason.clientIdRejected => l10n.connackClientId,
      ConnackReason.serverUnavailable => l10n.connackServerUnavailable,
      ConnackReason.badCredentials => l10n.connackBadCredentials,
      ConnackReason.notAuthorized => l10n.connackNotAuthorized,
      ConnackReason.unspecifiedError => l10n.connackUnspecified,
      ConnackReason.malformedPacket => l10n.connackMalformed,
      ConnackReason.protocolError => l10n.connackProtocolError,
      ConnackReason.implementationSpecificError => l10n.connackImplementation,
      ConnackReason.serverBusy => l10n.connackServerBusy,
      ConnackReason.banned => l10n.connackBanned,
      ConnackReason.badAuthenticationMethod => l10n.connackBadAuthMethod,
      ConnackReason.topicNameInvalid => l10n.connackTopicInvalid,
      ConnackReason.packetTooLarge => l10n.connackPacketTooLarge,
      ConnackReason.quotaExceeded => l10n.connackQuota,
      ConnackReason.payloadFormatInvalid => l10n.connackPayloadFormat,
      ConnackReason.retainNotSupported => l10n.connackRetainNotSupported,
      ConnackReason.qosNotSupported => l10n.connackQosNotSupported,
      ConnackReason.useAnotherServer => l10n.connackUseAnotherServer,
      ConnackReason.serverMoved => l10n.connackServerMoved,
      ConnackReason.connectionRateExceeded => l10n.connackRateExceeded,
      ConnackReason.unknown => l10n.connackUnknown,
    };

String? topicErrorText(AppLocalizations l10n, TopicError? error) =>
    switch (error) {
      null => null,
      TopicError.empty => l10n.mqttTopicErrorEmpty,
      TopicError.wildcard => l10n.mqttTopicErrorWildcard,
      TopicError.misplacedMultiLevel => l10n.mqttTopicErrorMultiLevel,
      TopicError.misplacedSingleLevel => l10n.mqttTopicErrorSingleLevel,
      TopicError.nullCharacter => l10n.mqttTopicErrorNull,
      TopicError.tooLong => l10n.mqttTopicErrorTooLong,
    };

/// Label, icon and colour of a connection status (icon + text, never
/// colour alone).
(String, IconData, Color) mqttStatusLook(
  BuildContext context,
  MqttConnectionStatus status,
) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final colors = context.appColors;
  return switch (status) {
    MqttConnectionStatus.disconnected => (
      l10n.mqttStatusDisconnected,
      Icons.cloud_off_outlined,
      scheme.onSurfaceVariant,
    ),
    MqttConnectionStatus.connecting => (
      l10n.mqttStatusConnecting,
      Icons.sync,
      colors.warning,
    ),
    MqttConnectionStatus.connected => (
      l10n.mqttStatusConnected,
      Icons.cloud_done_outlined,
      colors.success,
    ),
    MqttConnectionStatus.reconnecting => (
      l10n.mqttStatusReconnecting,
      Icons.sync_problem,
      colors.warning,
    ),
    MqttConnectionStatus.error => (
      l10n.mqttStatusError,
      Icons.error_outline,
      scheme.error,
    ),
  };
}

String transportLabel(MqttTransport t) => switch (t) {
  MqttTransport.tcp => 'TCP',
  MqttTransport.tls => 'TLS',
  MqttTransport.ws => 'WS',
  MqttTransport.wss => 'WSS',
};

String versionLabel(MqttProtocolVersion v) => switch (v) {
  MqttProtocolVersion.v311 => '3.1.1',
  MqttProtocolVersion.v5 => '5.0',
};
