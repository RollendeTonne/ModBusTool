import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_json.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';

final class ProfileRepository {
  new(this._store);

  static const documentName = 'connection_profiles.json';

  final DocumentStore _store;

  /// Returns `null` if no profiles were ever saved (first start), so the
  /// caller can seed defaults without overriding a deliberately empty list.
  Future<List<ConnectionProfile>?> load() async {
    final text = await _store.read(documentName);
    if (text == null) return null;
    try {
      return profilesFromJson(jsonDecode(text));
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<ConnectionProfile> profiles) => _store.write(
    documentName,
    const JsonEncoder.withIndent('  ').convert(profilesToJson(profiles)),
  );
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(documentStoreProvider)),
);
