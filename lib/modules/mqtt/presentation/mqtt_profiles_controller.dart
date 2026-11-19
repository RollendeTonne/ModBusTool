import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_repository.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';

final class MqttProfilesController extends AsyncNotifier<List<MqttProfile>> {
  static final _random = Random();

  /// The demo broker profile seeded on first start.
  static MqttProfile demoProfile() => MqttProfile(
    id: newId(),
    name: 'Demo-Broker (Simulator)',
    createdAt: DateTime.now(),
    config: const MqttConnectionConfig(
      host: 'simulator',
      simulated: true,
      protocolVersion: MqttProtocolVersion.v5,
      subscriptions: [
        MqttSubscriptionSpec(filter: 'demo/#'),
        MqttSubscriptionSpec(filter: r'$SYS/#'),
      ],
    ),
  );

  static String newId() =>
      'mqtt-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';

  MqttProfileRepository get _repository =>
      ref.read(mqttProfileRepositoryProvider);

  @override
  Future<List<MqttProfile>> build() async {
    final stored = await _repository.load();
    if (stored != null) return _sorted(stored);
    final seeded = [demoProfile()];
    await _repository.save(seeded);
    return seeded;
  }

  List<MqttProfile> get _current => state.value ?? const [];

  MqttProfile? byId(String id) => _current.where((p) => p.id == id).firstOrNull;

  Future<void> save(MqttProfile profile) async {
    final list = [..._current];
    final index = list.indexWhere((p) => p.id == profile.id);
    if (index < 0) {
      list.add(profile);
    } else {
      list[index] = profile;
    }
    await _persist(list);
  }

  Future<MqttProfile> duplicate(
    MqttProfile profile, {
    required String name,
  }) async {
    final copy = MqttProfile(
      id: newId(),
      name: name,
      config: profile.config,
      createdAt: DateTime.now(),
      autoReconnect: profile.autoReconnect,
    );
    // Secrets belong to a profile ID: copy them along.
    final secrets = await _repository.loadSecrets(profile.id);
    await _repository.saveSecrets(
      copy.id,
      password: secrets.password,
      clientKeyPem: secrets.clientKeyPem,
      clientKeyPassword: secrets.clientKeyPassword,
    );
    await _persist([..._current, copy]);
    return copy;
  }

  Future<void> delete(String id) async {
    await _repository.deleteSecrets(id);
    await _persist(_current.where((p) => p.id != id).toList());
  }

  Future<void> markUsed(String id) {
    final now = DateTime.now();
    return _persist(
      _current
          .map((p) => p.id == id ? p.copyWith(lastUsedAt: now) : p)
          .toList(),
    );
  }

  Future<void> _persist(List<MqttProfile> profiles) async {
    final sorted = _sorted(profiles);
    state = AsyncData(sorted);
    await _repository.save(sorted);
  }

  /// Most recently used first, never-used alphabetically after.
  static List<MqttProfile> _sorted(List<MqttProfile> profiles) =>
      [...profiles]..sort((a, b) {
        final au = a.lastUsedAt;
        final bu = b.lastUsedAt;
        if (au != null && bu != null) return bu.compareTo(au);
        if (au != null) return -1;
        if (bu != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
}

final mqttProfilesControllerProvider =
    AsyncNotifierProvider<MqttProfilesController, List<MqttProfile>>(
      MqttProfilesController.new,
    );
