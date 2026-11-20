import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/modules/mqtt/data/publish_template_repository.dart';
import 'package:modbus_explorer/modules/mqtt/domain/publish_template.dart';

final class PublishTemplatesController
    extends AsyncNotifier<List<PublishTemplate>> {
  @override
  Future<List<PublishTemplate>> build() =>
      ref.read(publishTemplateRepositoryProvider).load();

  List<PublishTemplate> get _current => state.value ?? const [];

  /// Adds, or replaces a template with the same name (case-insensitive).
  Future<void> save(PublishTemplate template) async {
    final name = template.name.trim().toLowerCase();
    final existing = _current
        .where((t) => t.name.trim().toLowerCase() == name)
        .firstOrNull;
    final saved = existing == null
        ? template
        : template.copyWith(id: existing.id);
    await _persist(
      [
        for (final t in _current)
          if (t.id != saved.id) t,
        saved,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  Future<void> delete(String id) => _persist([
    for (final t in _current)
      if (t.id != id) t,
  ]);

  Future<void> _persist(List<PublishTemplate> templates) async {
    state = AsyncData(templates);
    await ref.read(publishTemplateRepositoryProvider).save(templates);
  }

  static String newId() =>
      'tpl-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}

final publishTemplatesProvider =
    AsyncNotifierProvider<PublishTemplatesController, List<PublishTemplate>>(
      PublishTemplatesController.new,
    );
