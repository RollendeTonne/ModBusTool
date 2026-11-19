import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_repository.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';

final class ProfilesController extends AsyncNotifier<List<ConnectionProfile>> {
  static final _random = Random();

  @override
  Future<List<ConnectionProfile>> build() async {
    final repository = ref.read(profileRepositoryProvider);
    final stored = await repository.load();
    if (stored != null) return _sorted(stored);
    // First start: one ready-to-use profile so the app works immediately.
    final seeded = [
      ConnectionProfile(
        id: newProfileId(),
        name: 'Simulator (Demo)',
        config: const SimulatorConnectionConfig(),
        createdAt: DateTime.now(),
      ),
    ];
    await repository.save(seeded);
    return seeded;
  }

  static String newProfileId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';

  List<ConnectionProfile> get _current => state.value ?? const [];

  Future<void> save(ConnectionProfile profile) async {
    final list = [..._current];
    final index = list.indexWhere((p) => p.id == profile.id);
    if (index < 0) {
      list.add(profile);
    } else {
      list[index] = profile;
    }
    await _persist(list);
  }

  Future<ConnectionProfile> duplicate(
    ConnectionProfile profile, {
    required String name,
  }) async {
    // A new profile, so no lastUsedAt carried over.
    final copy = ConnectionProfile(
      id: newProfileId(),
      name: name,
      config: profile.config,
      createdAt: DateTime.now(),
      autoReconnect: profile.autoReconnect,
    );
    await _persist([..._current, copy]);
    return copy;
  }

  Future<void> delete(String id) =>
      _persist(_current.where((p) => p.id != id).toList());

  Future<void> markUsed(String id) {
    final now = DateTime.now();
    return _persist(
      _current
          .map((p) => p.id == id ? p.copyWith(lastUsedAt: now) : p)
          .toList(),
    );
  }

  Future<void> _persist(List<ConnectionProfile> profiles) async {
    final sorted = _sorted(profiles);
    state = AsyncData(sorted);
    await ref.read(profileRepositoryProvider).save(sorted);
  }

  /// Most recently used first, never-used profiles alphabetically after.
  static List<ConnectionProfile> _sorted(List<ConnectionProfile> profiles) =>
      [...profiles]..sort((a, b) {
        final au = a.lastUsedAt;
        final bu = b.lastUsedAt;
        if (au != null && bu != null) return bu.compareTo(au);
        if (au != null) return -1;
        if (bu != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
}

final profilesControllerProvider =
    AsyncNotifierProvider<ProfilesController, List<ConnectionProfile>>(
      ProfilesController.new,
    );
