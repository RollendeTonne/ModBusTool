import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_json.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/shared/profiles/profile_store.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

/// Modbus profiles inside the shared [ProfileStore].
final class ProfileRepository {
  new(this._store);

  final ProfileStore _store;

  /// Returns `null` if no profiles were ever saved (first start), so the
  /// caller can seed defaults without overriding a deliberately empty list.
  Future<List<ConnectionProfile>?> load() async {
    final entries = await _store.load(ProtocolModule.modbus);
    return entries == null ? null : profilesFromJson({'profiles': entries});
  }

  Future<void> save(List<ConnectionProfile> profiles) => _store.save(
    ProtocolModule.modbus,
    [for (final p in profiles) profileToJson(p)],
  );
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileStoreProvider)),
);
