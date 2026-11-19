import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

Future<void> openRegistersConnected(WidgetTester tester) async {
  await tester.tapNavigation('Registers');
  expect(find.textContaining('No data yet'), findsOneWidget);
  await tester.tap(find.byKey(const Key('registers.connectSimulator')));
  await tester.pumpAndSettle();
  expect(find.text('Connected'), findsOneWidget);
}

Future<void> setRange(WidgetTester tester, String address, String count) async {
  await tester.enterText(find.byKey(const Key('request.address')), address);
  await tester.enterText(find.byKey(const Key('request.count')), count);
  await tester.pump();
}

Future<void> read(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('request.read')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connect to simulator and read holding registers', (
    tester,
  ) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await read(tester);
    final list = find.byKey(const Key('registers.list'));
    expect(find.descendant(of: list, matching: find.text('40001')), findsOne);
    // FLOAT32 10.0 high word (ABCD at 0, CDAB at 2).
    expect(find.text('0x4120'), findsNWidgets(2));
    expect(find.text('16672'), findsWidgets);
    expect(find.textContaining('10 values'), findsOneWidget);
  });

  testWidgets('Ctrl+R reads the edited range', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await setRange(tester, '40025', '1');
    expect(find.text('= protocol address 24 (0x0018)'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('0xFB2E'), findsOneWidget); // INT16 -1234
    expect(find.text('-1234'), findsOneWidget);
  });

  testWidgets('invalid address disables reading', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await tester.enterText(find.byKey(const Key('request.address')), 'abc');
    await tester.pump();
    expect(find.text('Invalid value'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('request.read')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('device exception is explained', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await setRange(tester, '41001', '1');
    await read(tester);
    expect(find.byKey(const Key('registers.error')), findsOneWidget);
    expect(find.text('04 Server device failure'), findsOneWidget);
  });

  testWidgets('write register with confirmation', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await setRange(tester, '40301', '2');
    await read(tester);

    // Locked: write buttons disabled.
    final locked = tester.widget<IconButton>(
      find.byKey(const Key('write.300')),
    );
    expect(locked.onPressed, isNull);

    await tester.tap(find.byKey(const Key('request.writeUnlock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('write.300')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('writeRegister.value')),
      '0x2A',
    );
    await tester.pump();
    // Bit 1, 3 and 5 of 0x2A are set.
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('writeRegister.bit5')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('writeRegister.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm write'), findsOneWidget);
    expect(find.text('FC06 · 40301 = 0x002A (42)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmWrite.ok')));
    await tester.pumpAndSettle();

    expect(find.text('0x002A'), findsOneWidget);
    expect(find.textContaining('Written: FC06'), findsOneWidget);
  });

  testWidgets('cancelled confirmation does not write', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await setRange(tester, '40401', '1');
    await read(tester);
    await tester.tap(find.byKey(const Key('request.writeUnlock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('write.400')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('writeRegister.value')), '7');
    await tester.tap(find.byKey(const Key('writeRegister.submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('0x0000'), findsOneWidget);
  });

  testWidgets('coil switch writes FC05 without dialog when confirmation '
      'is disabled', (tester) async {
    await tester.pumpModbusApp(storedValues: {'settings.confirmWrites': false});
    await openRegistersConnected(tester);
    await tester.tap(find.text('Coils (0x)'));
    await tester.pumpAndSettle();
    await setRange(tester, '00002', '2');
    await read(tester);
    expect(find.text('OFF'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('request.writeUnlock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coil.1')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm write'), findsNothing);
    expect(find.text('ON'), findsOneWidget);
  });

  testWidgets('write multiple registers', (tester) async {
    await tester.pumpModbusApp(storedValues: {'settings.confirmWrites': false});
    await openRegistersConnected(tester);
    await setRange(tester, '40501', '3');
    await read(tester);
    await tester.tap(find.byKey(const Key('request.writeUnlock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registers.writeMultiple')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('writeMultiple.values')),
      '1, 0x10 0b11',
    );
    await tester.tap(find.byKey(const Key('writeMultiple.submit')));
    await tester.pumpAndSettle();
    expect(find.text('0x0001'), findsOneWidget);
    expect(find.text('0x0010'), findsOneWidget);
    expect(find.text('0x0003'), findsOneWidget);
  });

  testWidgets('polling shows statistics and can be stopped', (tester) async {
    await tester.pumpModbusApp();
    await openRegistersConnected(tester);
    await tester.tap(find.byKey(const Key('request.poll')));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.textContaining('Polls: '), findsOneWidget);
    await tester.tap(find.byKey(const Key('request.poll')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Polls: '), findsNothing);
  });
}
