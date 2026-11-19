import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_json.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/shared/profiles/profile_store.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

/// MQTT profiles in the shared document; secrets in the [SecretStore].
final class MqttProfileRepository {
  new(this._store, this._secrets);

  final ProfileStore _store;
  final SecretStore _secrets;

  static String passwordKey(String id) => 'mqtt.$id.password';
  static String clientKeyKey(String id) => 'mqtt.$id.clientKey';
  static String clientKeyPasswordKey(String id) => 'mqtt.$id.clientKeyPassword';

  /// `null` on first start (seed the demo profile then).
  Future<List<MqttProfile>?> load() async {
    final entries = await _store.load(ProtocolModule.mqtt);
    if (entries == null) return null;
    final profiles = <MqttProfile>[];
    for (final entry in entries) {
      try {
        profiles.add(mqttProfileFromJson(entry));
      } on Object {
        // Skip broken entries instead of losing all profiles.
      }
    }
    return profiles;
  }

  Future<void> save(List<MqttProfile> profiles) => _store.save(
    ProtocolModule.mqtt,
    [for (final p in profiles) mqttProfileToJson(p)],
  );

  Future<MqttSecrets> loadSecrets(String id) async => MqttSecrets(
    password: await _secrets.read(passwordKey(id)),
    clientKeyPem: await _secrets.read(clientKeyKey(id)),
    clientKeyPassword: await _secrets.read(clientKeyPasswordKey(id)),
  );

  /// Writes only the given values; pass `''` to delete one.
  Future<void> saveSecrets(
    String id, {
    String? password,
    String? clientKeyPem,
    String? clientKeyPassword,
  }) async {
    Future<void> put(String key, String? value) async {
      if (value == null) return;
      await _secrets.write(key, value.isEmpty ? null : value);
    }

    await put(passwordKey(id), password);
    await put(clientKeyKey(id), clientKeyPem);
    await put(clientKeyPasswordKey(id), clientKeyPassword);
  }

  Future<void> deleteSecrets(String id) async {
    await _secrets.write(passwordKey(id), null);
    await _secrets.write(clientKeyKey(id), null);
    await _secrets.write(clientKeyPasswordKey(id), null);
  }
}

final mqttProfileRepositoryProvider = Provider<MqttProfileRepository>(
  (ref) => MqttProfileRepository(
    ref.watch(profileStoreProvider),
    ref.watch(secretStoreProvider),
  ),
);
