import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/clipboard.dart';
import '../../../helpers/pump_app.dart';

Future<void> connectAndRead(
  WidgetTester tester, {
  String address = '40001',
  String count = '10',
}) async {
  await tester.tapNavigation('Registers');
  await tester.tap(find.byKey(const Key('registers.connectSimulator')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('request.address')), address);
  await tester.enterText(find.byKey(const Key('request.count')), count);
  await tester.tap(find.byKey(const Key('request.read')));
  await tester.pumpAndSettle();
}

Finder matrixCell(String type, String family) =>
    find.byKey(Key('matrix.$type.$family'));

/// The panel is a lazy list: scroll before interacting with lower cards.
Future<void> scrollPanelTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(
      target,
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('interpretation.panel')),
            matching: find.byType(Scrollable),
          )
          .first,
    );

String cellText(WidgetTester tester, Finder cell) => tester
    .widget<Text>(find.descendant(of: cell, matching: find.byType(Text)))
    .data!;

void main() {
  testWidgets('desktop: interpretation panel follows the selection', (
    tester,
  ) async {
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    await connectAndRead(tester);
    expect(find.byKey(const Key('interpretation.panel')), findsOneWidget);
    expect(find.text('Register 40001'), findsOneWidget);
    expect(cellText(tester, matrixCell('float32', 'abcd')), '10.0');

    await tester.tap(find.byKey(const Key('row.2')));
    await tester.pumpAndSettle();
    expect(find.text('Register 40003'), findsOneWidget);
    expect(cellText(tester, matrixCell('float32', 'cdab')), '10.0');

    // Shift+click selects a range: text interpretation of the demo string.
    await tester.enterText(find.byKey(const Key('request.address')), '40031');
    await tester.tap(find.byKey(const Key('request.read')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('row.30')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const Key('row.37')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.textContaining('8 register(s)'), findsOneWidget);
    await scrollPanelTo(tester, find.byKey(const Key('interpretation.text')));
    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('interpretation.text')))
          .data,
      '"Modbus Explorer"',
    );
  });

  testWidgets('desktop: scaling, copy and adding to the register map', (
    tester,
  ) async {
    final clipboard = FakeClipboard();
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    clipboard.install(tester);
    await connectAndRead(tester, address: '40071', count: '1');

    // Temperature × 10 → scaled.
    await scrollPanelTo(tester, find.byKey(const Key('scaling.factor')));
    await tester.enterText(find.byKey(const Key('scaling.factor')), '0,1');
    await tester.pumpAndSettle();
    // scrollUntilVisible stops once the cell is built, not when it is
    // actually visible; ensureVisible scrolls it into the viewport.
    await tester.ensureVisible(matrixCell('int16', 'abcd'));
    await tester.pumpAndSettle();
    final scaled = cellText(tester, matrixCell('int16', 'abcd'));
    expect(scaled, matches(RegExp(r'^\d+\.\d$')));

    await tester.tap(matrixCell('int16', 'abcd'));
    await tester.pumpAndSettle();
    expect(clipboard.text, scaled);
    expect(find.text('Copied: $scaled'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('matrix.copyTsv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('matrix.copyTsv')));
    await tester.pumpAndSettle();
    expect(clipboard.text, startsWith('Type\tABCD'));

    await tester.ensureVisible(matrixCell('int16', 'abcd'));
    await tester.pumpAndSettle();
    await tester.tap(
      matrixCell('int16', 'abcd'),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to register map…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mapEntry.label')), 'Boiler');
    await tester.tap(find.byKey(const Key('mapEntry.save')));
    await tester.pumpAndSettle();
    expect(find.text('Saved to register map: Boiler'), findsOneWidget);

    // Label column appears in the raw table.
    expect(
      find.descendant(
        of: find.byKey(const Key('row.70')),
        matching: find.text('Boiler'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Register map (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Boiler'), findsOneWidget);
    expect(find.textContaining('40071 · INT16 AB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('map.read')));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^\d+\.\d$')), findsWidgets);
  });

  testWidgets('register map: manual entry, search and delete', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    await connectAndRead(tester);
    await tester.tap(find.byKey(const Key('registers.view')).first);
    await tester.tap(find.text('Register map (0)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No entries yet'), findsOneWidget);

    for (final (label, address) in [('Alpha', '40021'), ('Beta', '40025')]) {
      await tester.tap(find.byKey(const Key('map.add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('mapEntry.label')), label);
      await tester.enterText(
        find.byKey(const Key('mapEntry.address')),
        address,
      );
      await tester.tap(find.byKey(const Key('mapEntry.save')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Register map (2)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('map.search')), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Beta'),
        matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete entry?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Register map (1)'), findsOneWidget);
  });

  testWidgets('phone: tapping a row opens the interpretation sheet', (
    tester,
  ) async {
    await tester.pumpModbusApp(size: const Size(390, 844));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Registers'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registers.connectSimulator')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request.read')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interpretation.panel')), findsNothing);

    // Scroll a bit past the row so the pinned header does not cover it.
    await tester.scrollUntilVisible(
      find.byKey(const Key('row.7')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('row.5')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interpretation.panel')), findsOneWidget);
    expect(find.text('Register 40006'), findsOneWidget);
  });
}
