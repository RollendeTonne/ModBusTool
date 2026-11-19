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
