import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/pump_app.dart';

/// Overflow errors fail widget tests, so rendering every page at typical
/// sizes in the longer German locale catches layout regressions.
void main() {
  const sizes = {
    'phone': Size(390, 844),
    'tablet': Size(820, 1180),
    'desktop': Size(1440, 900),
  };
  const destinations = ['Verbindung', 'Register', 'Monitor', 'Werkzeuge'];

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('all pages render on $name (de)', (tester) async {
      await tester.pumpModbusApp(size: size, locale: const Locale('de'));

      Future<void> go(String label) async {
        final target = size.width < 600
            ? find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              )
            : find.descendant(
                of: find.byType(NavigationRail),
                matching: find.text(label),
              );
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      for (final label in destinations) {
        await go(label);
      }

      // Registers with data and write unlocked (widest state).
      await go('Register');
      await tester.tap(find.byKey(const Key('registers.connectSimulator')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request.read')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request.writeUnlock')));
      await tester.pumpAndSettle();

      // Interpretation: side panel on wide screens, bottom sheet otherwise.
      final row = find.byKey(const Key('row.0'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row, warnIfMissed: false);
      await tester.pumpAndSettle();
      final panel = find.byKey(const Key('interpretation.panel'));
      expect(panel, findsOneWidget);
      // Render the lower cards of the (lazy) panel too.
      await tester.drag(panel, const Offset(0, -2000));
      await tester.pumpAndSettle();
      if (size.width < 1100) {
        Navigator.of(tester.element(panel)).pop(); // close the bottom sheet
        await tester.pumpAndSettle();
      }

      // Register map view and its entry dialog.
      final mapView = find.text('Register-Map (0)');
      await tester.ensureVisible(mapView);
      await tester.pumpAndSettle();
      await tester.tap(mapView);
      await tester.pumpAndSettle();
      final add = find.byKey(const Key('map.add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Monitor with frame details, then every tools tab.
      await go('Monitor');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('frame.0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('monitor.detail')), findsOneWidget);
      if (size.width < 1000) {
        Navigator.of(tester.element(find.byKey(const Key('monitor.detail'))))
            .pop();
        await tester.pumpAndSettle();
      }
      await go('Werkzeuge');
      for (final tab in ['Scanner', 'Statistik', 'Trend', 'Hex-Rechner']) {
        // The tab bar scrolls on phones.
        await tester.ensureVisible(find.text(tab));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }

      // Profile editor for every connection kind.
      await go('Verbindung');
      await tester.scrollUntilVisible(
        find.byKey(const Key('profiles.new')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('profiles.new')));
      await tester.pumpAndSettle();
      for (final kind in [
        'Modbus TCP',
        'Modbus RTU',
        'RTU über TCP',
        'Simulator',
      ]) {
        final segment = find.descendant(
          of: find.byKey(const Key('profileEditor.kind')),
          matching: find.text(kind),
        );
        await tester.ensureVisible(segment);
        await tester.tap(segment);
        await tester.pumpAndSettle();
      }
    });
  }
}
