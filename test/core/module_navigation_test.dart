import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    expect(find.textContaining('MQTT module is under construction'), findsOne);
    // The Modbus connection state is not shown in the MQTT module.
    expect(find.text('Disconnected'), findsNothing);
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
}
