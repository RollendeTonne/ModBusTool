import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/interpretation/data/register_map_codec.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/presentation/register_map_controller.dart';

String _baseName(WidgetRef ref) {
  final id = ref.read(currentProfileIdProvider);
  final profile = ref
      .read(profilesControllerProvider)
      .value
      ?.where((p) => p.id == id)
      .firstOrNull;
  final name = (profile?.name ?? 'register-map')
      .replaceAll(RegExp('[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp('-+'), '-');
  return 'register-map_$name';
}

Future<void> exportRegisterMap(
  BuildContext context,
  WidgetRef ref,
  ExchangeFileType type,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final entries = ref.read(currentMapEntriesProvider);
  final content = type == ExchangeFileType.csv
      ? registerMapToCsv(entries)
      : const JsonEncoder.withIndent('  ').convert(registerMapToJson(entries));
  final name = timestampedFileName(_baseName(ref), type.extension);
  try {
    final saved = await ref
        .read(fileExchangeProvider)
        .saveText(suggestedName: name, content: content, type: type);
    if (saved) messenger.showReplacing(l10n.exportSaved(name));
  } on Object catch (e) {
    messenger.showReplacing(l10n.exportFailed('$e'));
  }
}

/// Reads a JSON or CSV map, shows what was found and asks whether to add
/// to or replace the current map.
Future<void> importRegisterMap(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final profileId = ref.read(currentProfileIdProvider);
  if (profileId == null) {
    messenger.showReplacing(l10n.mapNoProfile);
    return;
  }
  final OpenedTextFile? file;
  try {
    file = await ref.read(fileExchangeProvider).openText(const [
      ExchangeFileType.json,
      ExchangeFileType.csv,
    ]);
  } on Object catch (e) {
    messenger.showReplacing(l10n.importFailed('$e'));
    return;
  }
  if (file == null || !context.mounted) return;

  final List<RegisterMapEntry> entries;
  final int skipped;
  try {
    if (file.extension == 'csv') {
      final result = registerMapFromCsv(
        file.content,
        newId: RegisterMapController.newEntryId,
      );
      entries = result.entries;
      skipped = result.errors.length;
    } else {
      final skippedItems = <Object?>[];
      // Fresh IDs so importing the same file twice doesn't collide.
      entries = [
        for (final e in registerMapFromJson(
          jsonDecode(file.content),
          skipped: skippedItems,
        ))
          e.copyWith(id: RegisterMapController.newEntryId()),
      ];
      skipped = skippedItems.length;
    }
  } on FormatException catch (e) {
    messenger.showReplacing(l10n.importFailed(e.message));
    return;
  }

  if (entries.isEmpty) {
    messenger.showReplacing(l10n.importNothing(file.name));
    return;
  }
  final replace = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importTitle),
      content: Text(
        [
          l10n.importSummary(entries.length, file!.name),
          if (skipped > 0) l10n.importSkipped(skipped),
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        OutlinedButton(
          key: const Key('import.replace'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.importReplace),
        ),
        FilledButton(
          key: const Key('import.add'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.importAdd),
        ),
      ],
    ),
  );
  if (replace == null) return;
  await ref
      .read(registerMapControllerProvider.notifier)
      .importEntries(profileId, entries, replace: replace);
  messenger.showReplacing(l10n.importDone(entries.length));
}
