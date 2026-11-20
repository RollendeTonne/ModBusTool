import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';

import '../helpers/fake_files.dart';
import '../helpers/pump_app.dart';

Future<FakeFileExchange> pumpWithFiles(WidgetTester tester) async {
  final files = FakeFileExchange();
  await tester.pumpModbusApp(
    size: const Size(1600, 1000),
    overrides: [fileExchangeProvider.overrideWithValue(files)],
  );
  return files;
}

Future<void> openMapView(WidgetTester tester) async {
  await tester.tapNavigation('Registers');
  await tester.tap(find.byKey(const Key('registers.connectSimulator')));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Register map ('));
  await tester.pumpAndSettle();
}

Future<void> chooseTransfer(
  WidgetTester tester,
  String key,
  String item,
) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

Future<void> pressShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  group('register map files', () {
    testWidgets('import CSV with a broken line, then export JSON and CSV', (
      tester,
    ) async {
      final files = await pumpWithFiles(tester);
      await openMapView(tester);
      files.toOpen.add(
        const OpenedTextFile(
          name: 'meter.csv',
          content:
              'table;address;label;unit;type;order\n'
              'holdingRegisters;52;Spannung;V;float32;ABCD\n'
              'holdingRegisters;x;Kaputt;;uint16;AB\n'
              'holdingRegisters;70;Temperatur;°C;int16;AB\n',
        ),
      );
      await chooseTransfer(tester, 'map.transfer', 'Import…');
      // Both sentences are in one dialog text.
      expect(find.textContaining('2 entries read from meter.csv.'), findsOne);
      expect(
        find.textContaining('1 entry could not be read'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('import.add')));
      await tester.pumpAndSettle();
      expect(find.text('Register map (2)'), findsOneWidget);
      expect(find.text('Spannung'), findsOneWidget);

      await chooseTransfer(tester, 'map.transfer', 'Export as JSON…');
      final json = jsonDecode(files.saved.last.content) as Map;
      expect((json['entries'] as List).map((e) => (e as Map)['label']), [
        'Spannung',
        'Temperatur',
      ]);
      expect(files.saved.last.name, startsWith('register-map_Simulator-Demo-'));
      expect(files.saved.last.name, endsWith('.json'));

      await chooseTransfer(tester, 'map.transfer', 'Export as CSV…');
      expect(files.saved.last.type, ExchangeFileType.csv);
      expect(files.saved.last.content.split('\n'), hasLength(3));
      expect(find.textContaining('Saved: register-map_'), findsOneWidget);
    });

    testWidgets('JSON import can replace the map', (tester) async {
      final files = await pumpWithFiles(tester);
      await openMapView(tester);
      String document(List<String> labels) => jsonEncode({
        'version': 1,
        'entries': [
          for (final (i, label) in labels.indexed)
            {
              'id': 'x$i',
              'table': 'holdingRegisters',
              'address': i,
              'label': label,
              'format': {'kind': 'numeric', 'type': 'uint16', 'order': 'AB'},
            },
        ],
      });
      files.toOpen
        ..add(OpenedTextFile(name: 'a.json', content: document(['A', 'B'])))
        ..add(OpenedTextFile(name: 'b.json', content: document(['C'])));
      await chooseTransfer(tester, 'map.transfer', 'Import…');
      await tester.tap(find.byKey(const Key('import.add')));
      await tester.pumpAndSettle();
      expect(find.text('Register map (2)'), findsOneWidget);

      await chooseTransfer(tester, 'map.transfer', 'Import…');
      await tester.tap(find.byKey(const Key('import.replace')));
      await tester.pumpAndSettle();
      expect(find.text('Register map (1)'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('unreadable files are reported', (tester) async {
      final files = await pumpWithFiles(tester);
      await openMapView(tester);
      files.toOpen.add(const OpenedTextFile(name: 'x.json', content: '{oops'));
      await chooseTransfer(tester, 'map.transfer', 'Import…');
      expect(find.textContaining('Import failed'), findsOneWidget);

      files.toOpen.add(const OpenedTextFile(name: 'e.csv', content: 'a;b\n'));
      await chooseTransfer(tester, 'map.transfer', 'Import…');
      expect(find.text('e.csv contains no readable entries.'), findsOneWidget);
    });
  });

  testWidgets('monitor log can be saved as CSV file', (tester) async {
    final files = await pumpWithFiles(tester);
    await tester.tapNavigation('Registers');
    await tester.tap(find.byKey(const Key('registers.connectSimulator')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request.read')));
    await tester.pumpAndSettle();
    await tester.tapNavigation('Monitor');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    await chooseTransfer(tester, 'monitor.export', 'Save as CSV file…');
    final saved = files.saved.single;
    expect(saved.name, startsWith('modbus-log_'));
    expect(saved.content, startsWith('timestamp;direction'));
    expect(saved.content.split('\n'), hasLength(3));
  });

  testWidgets('profiles round-trip through a file', (tester) async {
    final files = await pumpWithFiles(tester);
    await chooseTransfer(tester, 'profiles.transfer', 'Export profiles…');
    final exported = files.saved.single.content;
    expect(exported, contains('Simulator (Demo)'));

    files.toOpen.add(OpenedTextFile(name: 'p.json', content: exported));
    await chooseTransfer(tester, 'profiles.transfer', 'Import profiles…');
    expect(find.text('1 profile imported'), findsOneWidget);
    expect(find.text('Simulator (Demo)'), findsNWidgets(2));
  });

  group('keyboard shortcuts', () {
    testWidgets('Ctrl+1…5 switches areas', (tester) async {
      await tester.pumpModbusApp();
      for (final (key, title) in [
        (LogicalKeyboardKey.digit2, 'Registers'),
        (LogicalKeyboardKey.digit3, 'Monitor'),
        (LogicalKeyboardKey.digit4, 'Tools'),
        (LogicalKeyboardKey.digit5, 'Settings'),
        (LogicalKeyboardKey.digit1, 'Connection'),
      ]) {
        await pressShortcut(tester, key);
        expect(find.widgetWithText(AppBar, title), findsOneWidget);
      }
    });

    testWidgets('Ctrl+P toggles polling', (tester) async {
      await tester.pumpModbusApp();
      await tester.tapNavigation('Registers');
      await tester.tap(find.byKey(const Key('registers.connectSimulator')));
      await tester.pumpAndSettle();
      await pressShortcut(tester, LogicalKeyboardKey.keyP);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Polls:'), findsOneWidget);
      await pressShortcut(tester, LogicalKeyboardKey.keyP);
      expect(find.textContaining('Polls:'), findsNothing);
    });

    testWidgets('settings list the shortcuts', (tester) async {
      await tester.pumpModbusApp();
      await tester.tapNavigation('Settings');
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings.shortcuts')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Start/stop polling'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('ProtocollExplorer 2.0.0'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.textContaining('ProtocollExplorer 2.0.0'), findsOneWidget);
    });
  });
}
