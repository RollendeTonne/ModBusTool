import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/app.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/core/storage/sandbox_migration.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDirectory = await getApplicationSupportDirectory();
  if (Platform.isMacOS) {
    // Must run before SharedPreferences reads the settings.
    await SandboxMigration(
      home: Platform.environment['HOME'] ?? '',
      bundleId: 'de.example.modbusExplorer',
      supportDirectory: supportDirectory,
    ).run();
  }
  final store = await SharedPreferencesStore.create();
  final documents = FileDocumentStore(supportDirectory);
  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        documentStoreProvider.overrideWithValue(documents),
      ],
      child: const ModbusExplorerApp(),
    ),
  );
}
