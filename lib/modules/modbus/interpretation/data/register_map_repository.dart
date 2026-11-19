import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/data/register_map_codec.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';

/// Register maps per connection profile, in one JSON document.
final class RegisterMapRepository {
  new(this._store);

  static const documentName = 'register_maps.json';

  final DocumentStore _store;

  Future<Map<String, List<RegisterMapEntry>>> load() async {
    final text = await _store.read(documentName);
    if (text == null) return {};
    try {
      final json = jsonDecode(text);
      final maps = json is Map ? json['maps'] : null;
      if (maps is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in maps.entries)
          key as String: entriesFromJsonList(value),
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> save(Map<String, List<RegisterMapEntry>> maps) => _store.write(
    documentName,
    const JsonEncoder.withIndent('  ').convert({
      'version': registerMapSchemaVersion,
      'maps': {
        for (final MapEntry(:key, :value) in maps.entries)
          if (value.isNotEmpty) key: [for (final e in value) entryToJson(e)],
      },
    }),
  );
}

final registerMapRepositoryProvider = Provider<RegisterMapRepository>(
  (ref) => RegisterMapRepository(ref.watch(documentStoreProvider)),
);
