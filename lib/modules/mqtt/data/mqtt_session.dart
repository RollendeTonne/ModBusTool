import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';

/// Secrets of a profile, loaded from the secret store right before
/// connecting.
final class MqttSecrets {
  const new({this.password, this.clientKeyPem, this.clientKeyPassword});

  final String? password;
  final String? clientKeyPem;
  final String? clientKeyPassword;
}

/// One broker connection, independent of the MQTT package and protocol
/// version. Not reusable: create a new session to reconnect.
abstract interface class MqttSession {
  /// The client ID actually used (generated if the profile has none).
  String get clientId;

  /// Messages received from the broker.
  Stream<MqttMessageRecord> get messages;

  /// Emits once if the connection drops without [disconnect] being called.
  Stream<MqttConnectFailure> get connectionLost;

  /// Throws [MqttConnectFailure].
  Future<void> connect();

  void subscribe(MqttSubscriptionSpec subscription);

  void unsubscribe(String filter);

  /// Returns the record of the sent message (for the log).
  MqttMessageRecord publish(MqttOutgoingMessage message);

  Future<void> disconnect();
}
