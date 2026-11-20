import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/mqtt/domain/publish_template.dart';

/// Publish templates (favourites) in one versioned JSON document, shared
/// by all broker profiles.
final class PublishTemplateRepository {
  new(this._store);

  static const documentName = 'mqtt_publish_templates.json';
  static const schemaVersion = 1;

  final DocumentStore _store;

  Future<List<PublishTemplate>> load() async {
    final text = await _store.read(documentName);
    if (text == null) return const [];
    try {
      final json = jsonDecode(text);
      final list = json is Map ? json['templates'] : null;
      if (list is! List) return const [];
      return [
        for (final entry in list)
          if (entry is Map<String, Object?>) ?_tryParse(entry),
      ];
    } on FormatException {
      return const [];
    }
  }

  static PublishTemplate? _tryParse(Map<String, Object?> json) {
    try {
      return PublishTemplate.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> save(List<PublishTemplate> templates) => _store.write(
    documentName,
    const JsonEncoder.withIndent('  ').convert({
      'version': schemaVersion,
      'templates': [for (final t in templates) t.toJson()],
    }),
  );
}

final publishTemplateRepositoryProvider = Provider<PublishTemplateRepository>(
  (ref) => PublishTemplateRepository(ref.watch(documentStoreProvider)),
);
