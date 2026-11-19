import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/app.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPreferencesStore.create();
  final documents = FileDocumentStore(await getApplicationSupportDirectory());
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
