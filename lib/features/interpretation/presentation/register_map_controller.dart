import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/interpretation/data/register_map_repository.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';

final class RegisterMapController
    extends AsyncNotifier<Map<String, List<RegisterMapEntry>>> {
  static final _random = Random();

  @override
  Future<Map<String, List<RegisterMapEntry>>> build() =>
      ref.read(registerMapRepositoryProvider).load();

  static String newEntryId() =>
      'e${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';

  Map<String, List<RegisterMapEntry>> get _maps => state.value ?? const {};

  Future<void> saveEntry(String profileId, RegisterMapEntry entry) {
    final list = [...?_maps[profileId]];
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index < 0) {
      list.add(entry);
    } else {
      list[index] = entry;
    }
    return _persist(profileId, list);
  }

  Future<void> deleteEntry(String profileId, String entryId) => _persist(
    profileId,
    [...?_maps[profileId]]..removeWhere((e) => e.id == entryId),
  );

  /// Adds [entries] (e.g. from an import), optionally replacing the map.
  Future<void> importEntries(
    String profileId,
    List<RegisterMapEntry> entries, {
    bool replace = false,
  }) => _persist(profileId, [if (!replace) ...?_maps[profileId], ...entries]);

  Future<void> _persist(
    String profileId,
    List<RegisterMapEntry> entries,
  ) async {
    final maps = {..._maps, profileId: sortEntries(entries)};
    state = AsyncData(maps);
    await ref.read(registerMapRepositoryProvider).save(maps);
  }

  static List<RegisterMapEntry> sortEntries(List<RegisterMapEntry> entries) =>
      [...entries]..sort((a, b) {
        final byTable = a.table.index.compareTo(b.table.index);
        return byTable != 0 ? byTable : a.address.compareTo(b.address);
      });
}

final registerMapControllerProvider =
    AsyncNotifierProvider<
      RegisterMapController,
      Map<String, List<RegisterMapEntry>>
    >(RegisterMapController.new);

/// Profile whose register map is shown: the connected one, otherwise the
/// most recently used.
final currentProfileIdProvider = Provider<String?>((ref) {
  final connected = ref.watch(connectionControllerProvider).profile;
  if (connected != null) return connected.id;
  final profiles = ref.watch(profilesControllerProvider).value;
  return profiles == null || profiles.isEmpty ? null : profiles.first.id;
});

final currentMapEntriesProvider = Provider<List<RegisterMapEntry>>((ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  final maps = ref.watch(registerMapControllerProvider).value;
  if (profileId == null || maps == null) return const [];
  return maps[profileId] ?? const [];
});
