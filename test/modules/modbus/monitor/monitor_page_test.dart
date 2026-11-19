import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/clipboard.dart';
import '../../../helpers/pump_app.dart';

Future<void> connectAndRead(
  WidgetTester tester, {
  String address = '40001',
}) async {
  await tester.tapNavigation('Registers');
  if (find
      .byKey(const Key('registers.connectSimulator'))
      .evaluate()
      .isNotEmpty) {
    await tester.tap(find.byKey(const Key('registers.connectSimulator')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const Key('request.address')), address);
  await tester.tap(find.byKey(const Key('request.read')));
  await tester.pumpAndSettle();
}

/// The log batches updates; give the flush timer a chance to fire.
Future<void> settleLog(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('frames appear and can be decoded', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    await tester.tapNavigation('Monitor');
    expect(find.textContaining('No frames yet'), findsOneWidget);

    await connectAndRead(tester);
    await tester.tapNavigation('Monitor');
    await settleLog(tester);
    expect(find.text('2 of 2 frames'), findsOneWidget);
    expect(find.text('TX'), findsOneWidget);
    expect(find.text('RX'), findsOneWidget);
    expect(find.text('Select a frame to see its decoding.'), findsOneWidget);

    // Newest first: frame.0 is the response.
    await tester.tap(find.byKey(const Key('frame.0')));
    await tester.pumpAndSettle();
    final fields = find.byKey(const Key('monitor.fields'));
    for (final label in ['Transaction ID', 'Unit ID', 'Byte count', 'Values']) {
      expect(
        find.descendant(of: fields, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(find.text('Transaction #1'), findsOneWidget);
    expect(find.textContaining('Success'), findsOneWidget);
  });

  testWidgets('errors-only and function filters', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    await connectAndRead(tester);
    await connectAndRead(tester, address: '41001'); // exception 04
    await tester.tapNavigation('Monitor');
    await settleLog(tester);
    expect(find.text('4 of 4 frames'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monitor.errorsOnly')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 4 frames'), findsOneWidget);
    expect(find.text('FC83'), findsOneWidget);
    expect(find.text('Exception'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monitor.errorsOnly')));
    await tester.tap(find.byKey(const Key('monitor.function')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FC06 writeSingleRegister').last);
    await tester.pumpAndSettle();
    expect(find.text('0 of 4 frames'), findsOneWidget);
  });

  testWidgets('pause, clear and export', (tester) async {
    final clipboard = FakeClipboard();
    await tester.pumpModbusApp(size: const Size(1600, 1000));
    clipboard.install(tester);
    await connectAndRead(tester);
    await tester.tapNavigation('Monitor');
    await settleLog(tester);

    await tester.tap(find.byKey(const Key('monitor.export')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy as CSV'));
    await tester.pumpAndSettle();
    expect(clipboard.text!.split('\n'), hasLength(3));
    expect(clipboard.text, startsWith('timestamp;direction'));
    expect(find.text('2 frames copied'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monitor.pause')));
    await tester.pumpAndSettle();
    await connectAndRead(tester);
    await tester.tapNavigation('Monitor');
    await settleLog(tester);
    expect(find.text('Paused – 2 frames not recorded'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monitor.pause')));
    await tester.tap(find.byKey(const Key('monitor.clear')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No frames yet'), findsOneWidget);
  });

  testWidgets('phone: frame details open in a bottom sheet', (tester) async {
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
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Monitor'),
      ),
    );
    await settleLog(tester);
    await tester.tap(find.byKey(const Key('frame.1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monitor.detail')), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
  });
}
