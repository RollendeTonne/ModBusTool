import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';

import 'helpers/pump_app.dart';

void main() {
  group('App shell', () {
    testWidgets('desktop width shows an extended navigation rail', (
      tester,
    ) async {
      await tester.pumpModbusApp();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('phone width shows a bottom navigation bar', (tester) async {
      await tester.pumpModbusApp(size: const Size(390, 844));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('navigates between all destinations', (tester) async {
      await tester.pumpModbusApp();
      for (final label in ['Registers', 'Monitor', 'Tools', 'Settings']) {
        await tester.tapNavigation(label);
        expect(find.widgetWithText(AppBar, label), findsOneWidget);
      }
    });

    testWidgets('shows disconnected status chip', (tester) async {
      await tester.pumpModbusApp();
      expect(find.text('Disconnected'), findsOneWidget);
    });
  });

  group('Localization', () {
    testWidgets('follows German system locale', (tester) async {
      await tester.pumpModbusApp(locale: const Locale('de', 'DE'));
      expect(find.widgetWithText(AppBar, 'Verbindung'), findsOneWidget);
      expect(find.text('Getrennt'), findsOneWidget);
    });

    testWidgets('falls back to English for unsupported system locale', (
      tester,
    ) async {
      await tester.pumpModbusApp(locale: const Locale('fr', 'FR'));
      expect(find.widgetWithText(AppBar, 'Connection'), findsOneWidget);
    });

    testWidgets('language override in settings switches and persists', (
      tester,
    ) async {
      final store = await tester.pumpModbusApp();
      await tester.tapNavigation('Settings');
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Einstellungen'), findsOneWidget);
      expect(store.getString('settings.locale'), 'de');
    });
  });

  group('Settings', () {
    testWidgets('dark theme preference is applied', (tester) async {
      await tester.pumpModbusApp(storedValues: {'settings.theme': 'dark'});
      final context = tester.element(find.byType(NavigationRail));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('addressing hint updates with the selected mode', (
      tester,
    ) async {
      final store = await tester.pumpModbusApp();
      await tester.tapNavigation('Settings');
      expect(find.textContaining('40001'), findsWidgets);
      await tester.tap(find.text('0-based (protocol)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('exactly as sent'), findsOneWidget);
      expect(store.getString('settings.addressingMode'), 'zeroBased');
    });
  });

  group('Capabilities', () {
    testWidgets('serial transport is shown as unavailable on iOS', (
      tester,
    ) async {
      await tester.pumpModbusApp(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            PlatformCapabilities.forPlatform(TargetPlatform.iOS),
          ),
        ],
      );
      expect(
        find.text('Serial ports are not available on this platform.'),
        findsOneWidget,
      );
    });
  });
}
