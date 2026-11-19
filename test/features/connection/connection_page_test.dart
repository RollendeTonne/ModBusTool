import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('first start shows the seeded simulator profile', (tester) async {
    await tester.pumpModbusApp();
    expect(find.text('Simulator (Demo)'), findsOneWidget);
    expect(find.text('Never used'), findsOneWidget);
    expect(find.text('Not connected'), findsWidgets);
  });

  testWidgets('connect and disconnect from the profile list', (tester) async {
    await tester.pumpModbusApp();
    await tester.tap(find.widgetWithText(FilledButton, 'Connect').first);
    await tester.pumpAndSettle();
    expect(find.text('Connected to Simulator (Demo)'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining('Last used'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Not connected'), findsWidgets);
  });

  testWidgets('create a TCP profile with validation', (tester) async {
    await tester.pumpModbusApp();
    await tester.tap(find.byKey(const Key('profiles.new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profileEditor.name')), 'PLC');
    await tester.tap(find.text('Modbus TCP').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profileEditor.save')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profileEditor.host')),
      '10.0.0.5',
    );
    await tester.tap(find.byKey(const Key('profileEditor.save')));
    await tester.pumpAndSettle();
    expect(find.text('PLC'), findsOneWidget);
    expect(find.textContaining('10.0.0.5:502 · ID 1'), findsOneWidget);
  });

  testWidgets('RTU editor pre-selects the USB adapter', (tester) async {
    await tester.pumpModbusApp();
    await tester.tap(find.byKey(const Key('profiles.new')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modbus RTU').last);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('profileEditor.serialPort')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '/dev/ttyUSB0');
    expect(find.text('19200'), findsOneWidget);
  });

  testWidgets('failed connection shows a localized explanation', (
    tester,
  ) async {
    // The fake serial service fails to open ports like an unplugged
    // adapter.
    await tester.pumpModbusApp(locale: const Locale('de'));
    await tester.tap(find.byKey(const Key('profiles.new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profileEditor.name')), 'Weg');
    await tester.tap(find.text('Modbus RTU').last);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profileEditor.serialPort')),
      'COM99',
    );
    await tester.tap(find.byKey(const Key('profileEditor.save')));
    await tester.pumpAndSettle();
    // Never-used profiles sort alphabetically: "Simulator (Demo)" first.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Weg'),
        matching: find.text('Verbinden'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verbindung zu Weg fehlgeschlagen'), findsOneWidget);
    expect(find.text('Serielle Schnittstelle nicht verfügbar'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
