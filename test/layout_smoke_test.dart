import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profile_editor.dart';

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
      // The table is a lazy sliver below the request panel: build it first.
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
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
      for (final tab in [
        'Scanner',
        'Netzwerk',
        'Statistik',
        'Trend',
        'Hex-Rechner',
      ]) {
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
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Live MQTT data would keep the tree's change highlight animating.
      tester.useReducedMotion();
      await tester.pump();

      // MQTT module: editor in its widest state (TLS, last will, warning).
      await tester.tap(find.byKey(const Key('module.mqtt')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mqtt.profiles.new')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('mqttEditor.transport')),
          matching: find.text('TLS'),
        ),
      );
      await tester.pumpAndSettle();
      final editorList = find
          .descendant(
            of: find.byType(MqttProfileEditor),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final key in [
        'mqttEditor.willEnabled',
        'mqttEditor.acceptInvalid',
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(Key(key)),
          200,
          scrollable: editorList,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }
      await tester.drag(editorList, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Connected to the demo broker with live messages.
      await tester.tap(find.text('Demo-Broker (Simulator)'));
      await tester.pumpAndSettle();
      await go('Topics');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      // Tree fully expanded, a topic selected, then every tab (layouts
      // below 1000 px content width use tabs).
      await tester.tap(find.byKey(const Key('mqtt.tree.expandAll')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('mqtt.tree.row.demo/plant/line1/temperature')),
      );
      await tester.pumpAndSettle();
      for (final tab in ['Baum', 'Details', 'Abos', 'Publish']) {
        final finder = find.widgetWithText(Tab, tab);
        if (finder.evaluate().isEmpty) continue;
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
      await go('Monitor');
      await go('Verbindung');
      await tester.tap(find.byKey(const Key('mqtt.disconnect')));
      await tester.pumpAndSettle();
    });
  }
}
