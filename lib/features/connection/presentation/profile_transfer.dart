import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/connection/data/profile_json.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';

Future<void> exportProfiles(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final profiles = ref.read(profilesControllerProvider).value ?? const [];
  final name = timestampedFileName('modbus-profiles', 'json');
  try {
    final saved = await ref
        .read(fileExchangeProvider)
        .saveText(
          suggestedName: name,
          content: const JsonEncoder.withIndent('  ')
              .convert(profilesToJson(profiles)),
          type: ExchangeFileType.json,
        );
    if (saved) messenger.showReplacing(l10n.exportSaved(name));
  } on Object catch (e) {
    messenger.showReplacing(l10n.exportFailed('$e'));
  }
}

/// Imported profiles get new IDs (no collisions, register maps stay with
/// the original profiles) and no "last used" date.
Future<void> importProfiles(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final file = await ref.read(fileExchangeProvider).openText(const [
      ExchangeFileType.json,
    ]);
    if (file == null) return;
    final imported = profilesFromJson(jsonDecode(file.content));
    if (imported.isEmpty) {
      messenger.showReplacing(l10n.importNothing(file.name));
      return;
    }
    final controller = ref.read(profilesControllerProvider.notifier);
    for (final p in imported) {
      await controller.save(
        ConnectionProfile(
          id: ProfilesController.newProfileId(),
          name: p.name,
          config: p.config,
          createdAt: DateTime.now(),
          autoReconnect: p.autoReconnect,
        ),
      );
    }
    messenger.showReplacing(l10n.profilesImported(imported.length));
  } on FormatException catch (e) {
    messenger.showReplacing(l10n.importFailed(e.message));
  } on Object catch (e) {
    messenger.showReplacing(l10n.importFailed('$e'));
  }
}
