import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profiles_controller.dart';

import '../../helpers/container.dart';

/// Found on a phone: a profile saved before the list had ever loaded
/// (network scan → MQTT on first start) was overwritten by the seeding.
void main() {
  test('MQTT profile saved during the first load survives', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final profiles = container.read(mqttProfilesControllerProvider.notifier);
    await profiles.save(
      MqttProfile(
        id: 'scan',
        name: 'broker.local',
        createdAt: DateTime(2026),
        config: const MqttConnectionConfig(host: '192.168.50.7'),
      ),
    );
    final list = await container.read(mqttProfilesControllerProvider.future);
    expect(
      list.map((p) => p.name),
      containsAll(['broker.local', 'Demo-Broker (Simulator)']),
    );
  });

  test('Modbus profile saved during the first load survives', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final profiles = container.read(profilesControllerProvider.notifier);
    await profiles.save(
      ConnectionProfile(
        id: 'scan',
        name: 'plc7.local',
        createdAt: DateTime(2026),
        config: const TcpConnectionConfig(host: '192.168.50.10'),
      ),
    );
    final list = await container.read(profilesControllerProvider.future);
    expect(
      list.map((p) => p.name),
      containsAll(['plc7.local', 'Simulator (Demo)']),
    );
  });
}
