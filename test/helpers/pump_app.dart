import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/app.dart';
import 'package:modbus_explorer/core/routing/app_router.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/modbus_providers.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';

import 'fake_serial.dart';

extension PumpApp on WidgetTester {
  /// Pumps the full app with an in-memory store and a fixed window size.
  Future<KeyValueStore> pumpModbusApp({
    Size size = const Size(1280, 800),
    Locale locale = const Locale('en'),
    Map<String, Object>? storedValues,
    Map<String, String>? documents,
    SecretStore? secrets,
    List<Override> overrides = const [],
  }) async {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    platformDispatcher.localesTestValue = [locale];
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearLocalesTestValue);

    final store = InMemoryKeyValueStore(storedValues);
    await pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          documentStoreProvider.overrideWithValue(
            InMemoryDocumentStore(documents),
          ),
          // No animation timer: widget tests fail on pending timers.
          simulatorBankProvider.overrideWithValue(SimulatorBank.demo()),
          // Keychain/Keystore plugins are unavailable in tests.
          secretStoreProvider.overrideWithValue(
            secrets ?? InMemorySecretStore(),
          ),
          // Platform plugins are unavailable in widget tests.
          serialPortServiceProvider.overrideWithValue(
            const FakeSerialPortService(),
          ),
          // Fresh router per test; the default provider would be shared state.
          appRouterProvider.overrideWith((ref) => createAppRouter()),
          ...overrides,
        ],
        child: const ModbusExplorerApp(),
      ),
    );
    await pumpAndSettle();
    return store;
  }
}

extension NavigateTo on WidgetTester {
  /// Taps the navigation label itself; tapping the rail's centre would miss.
  Future<void> tapNavigation(String label) async {
    await tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(label),
      ),
    );
    await pumpAndSettle();
  }
}
