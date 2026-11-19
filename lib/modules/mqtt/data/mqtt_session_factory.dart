import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt311_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt5_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/simulated_broker.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';

typedef MqttSessionFactory = MqttSession Function(
  MqttConnectionConfig config,
  MqttSecrets secrets,
);

final mqttSessionFactoryProvider = Provider<MqttSessionFactory>((ref) {
  final broker = ref.watch(simulatedBrokerProvider);
  return (config, secrets) => config.simulated
      ? SimulatedMqttSession(broker, config)
      : switch (config.protocolVersion) {
          MqttProtocolVersion.v311 => Mqtt311Session(config, secrets),
          MqttProtocolVersion.v5 => Mqtt5Session(config, secrets),
        };
});
