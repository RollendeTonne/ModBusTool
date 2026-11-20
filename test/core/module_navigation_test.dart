import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/routing/active_module.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_page.dart';

import '../helpers/pump_app.dart';

void main() {
  Finder railLabel(String text) => find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(text),
  );

  Future<void> switchTo(WidgetTester tester, String module) async {
    await tester.tap(find.byKey(Key('module.$module')));
    await tester.pumpAndSettle();
  }

  testWidgets('module switcher swaps the destinations', (tester) async {
    await tester.pumpModbusApp();
    expect(railLabel('Registers'), findsOneWidget);
    expect(railLabel('Topics'), findsNothing);
    expect(find.text('Disconnected'), findsOneWidget);

    await switchTo(tester, 'mqtt');
    expect(railLabel('Topics'), findsOneWidget);
    expect(railLabel('Registers'), findsNothing);
    expect(railLabel('Settings'), findsOneWidget);
    expect(find.byKey(const Key('mqtt.connectionPage')), findsOneWidget);
    // The MQTT status replaces the Modbus one.
    expect(find.byKey(const Key('mqtt.statusChip')), findsOneWidget);
  });

  testWidgets('each module returns to where it was left', (tester) async {
    await tester.pumpModbusApp();
    await tester.tapNavigation('Monitor');
    await switchTo(tester, 'mqtt');
    await tester.tapNavigation('Topics');
    await switchTo(tester, 'modbus');
    expect(find.widgetWithText(AppBar, 'Monitor'), findsOneWidget);
    await switchTo(tester, 'mqtt');
    expect(find.widgetWithText(AppBar, 'Topics'), findsOneWidget);
  });

  testWidgets('settings are shared and stay open when switching', (
    tester,
  ) async {
    await tester.pumpModbusApp();
    await tester.tapNavigation('Settings');
    await switchTo(tester, 'mqtt');
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(railLabel('Topics'), findsOneWidget);
  });

  testWidgets('Ctrl+Shift+M toggles the module, Ctrl+2 picks a tab', (
    tester,
  ) async {
    await tester.pumpModbusApp();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(railLabel('Topics'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Topics'), findsOneWidget);
  });

  testWidgets('phone: switcher and compact status fit the app bar', (
    tester,
  ) async {
    await tester.pumpModbusApp(size: const Size(360, 740));
    expect(find.byKey(const Key('app.moduleSwitch')), findsOneWidget);
    await switchTo(tester, 'mqtt');
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Topics'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last module is remembered across restarts', (tester) async {
    final store = await tester.pumpModbusApp();
    await switchTo(tester, 'mqtt');
    expect(store.getString(ActiveModuleController.storageKey), 'mqtt');

    // "Restart" with the stored value: the app opens in MQTT.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpModbusApp(
      storedValues: {ActiveModuleController.storageKey: 'mqtt'},
    );
    expect(find.byKey(const Key('mqtt.connectionPage')), findsOneWidget);
    expect(railLabel('Topics'), findsOneWidget);
  });

  testWidgets('settings list the module and MQTT shortcuts', (tester) async {
    await tester.pumpModbusApp();
    await tester.tapNavigation('Settings');
    final table = find.byKey(const Key('settings.shortcuts'));
    await tester.scrollUntilVisible(
      table,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Ctrl + Shift + M'), findsOneWidget);
    expect(find.text('Switch module (Modbus ↔ MQTT)'), findsOneWidget);
    expect(find.text('MQTT: clear the monitor'), findsOneWidget);
  });
}
