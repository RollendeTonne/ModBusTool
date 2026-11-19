import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

/// One profile document for all modules. Each entry carries a `module`
/// field; a module only reads and replaces its own entries, so saving
/// Modbus profiles never drops MQTT ones and vice versa.
///
/// Entries are raw JSON maps: the modules own their profile formats.
final class ProfileStore {
  new(this._store);

  static const documentName = 'connection_profiles.json';

  /// 1: Modbus only, entries without `module`. 2: `module` per entry and
  /// the list of modules that have saved at least once.
  static const schemaVersion = 2;

  final DocumentStore _store;

  /// Module of an entry; entries from schema 1 have none and are Modbus.
  static ProtocolModule moduleOf(Map<String, Object?> entry) {
    final name = entry['module'];
    return ProtocolModule.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ProtocolModule.modbus,
    );
  }

  /// `null` if [module] never saved profiles (first start), so the caller
  /// can seed defaults without overriding a deliberately empty list.
  Future<List<Map<String, Object?>>?> load(ProtocolModule module) async {
    final doc = await _readDocument();
    if (doc == null) return null;
    if (!_initialized(doc).contains(module)) return null;
    return [
      for (final entry in _entries(doc))
        if (moduleOf(entry) == module) entry,
    ];
  }

  Future<void> save(
    ProtocolModule module,
    List<Map<String, Object?>> entries,
  ) async {
    final doc = await _readDocument();
    final others = [
      if (doc != null)
        for (final entry in _entries(doc))
          if (moduleOf(entry) != module) entry,
    ];
    final initialized = {if (doc != null) ..._initialized(doc), module};
    await _store.write(
      documentName,
      const JsonEncoder.withIndent('  ').convert({
        'version': schemaVersion,
        'modules': [
          for (final m in ProtocolModule.values)
            if (initialized.contains(m)) m.name,
        ],
        'profiles': [
          ...others,
          for (final entry in entries) {...entry, 'module': module.name},
        ],
      }),
    );
  }

  Future<Map<String, Object?>?> _readDocument() async {
    final text = await _store.read(documentName);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      // A corrupt file counts as "exists but empty", never as first start.
      return json is Map<String, Object?> ? json : const {};
    } on FormatException {
      return const {};
    }
  }

  static List<Map<String, Object?>> _entries(Map<String, Object?> doc) => [
    if (doc['profiles'] case final List<Object?> list)
      for (final entry in list)
        if (entry is Map<String, Object?>) entry,
  ];

  static Set<ProtocolModule> _initialized(Map<String, Object?> doc) {
    final modules = doc['modules'];
    // Schema 1 (or corrupt): only Modbus existed.
    if (modules is! List) return {ProtocolModule.modbus};
    return {
      for (final m in ProtocolModule.values)
        if (modules.contains(m.name)) m,
    };
  }
}

final profileStoreProvider = Provider<ProfileStore>(
  (ref) => ProfileStore(ref.watch(documentStoreProvider)),
);
