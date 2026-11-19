import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

import '../../helpers/pump_app.dart';

Finder matrixCell(String type, String family) =>
    find.byKey(Key('matrix.$type.$family'));

String textIn(WidgetTester tester, Finder finder) => tester
    .widget<Text>(find.descendant(of: finder, matching: find.byType(Text)))
    .data!;

/// Lazy list: build the target by scrolling, then bring it fully into view.
Future<void> reveal(WidgetTester tester, Finder target, String listKey) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(Key(listKey)),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> openTools(WidgetTester tester, {String? tab}) async {
  await tester.tapNavigation('Tools');
  if (tab != null) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }
}

Future<void> connectSimulator(WidgetTester tester) async {
  await tester.tapNavigation('Registers');
  await tester.tap(find.byKey(const Key('registers.connectSimulator')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hex calculator interprets input and encodes values', (
    tester,
  ) async {
    await tester.pumpModbusApp(size: const Size(1600, 1100));
    await openTools(tester);
    expect(textIn(tester, matrixCell('float32', 'abcd')), '10.0');

    await tester.enterText(find.byKey(const Key('hex.input')), '41 2z');
    await tester.pump();
    expect(find.text('Cannot read “2z”'), findsOneWidget);

    // FLOAT64 pi in EFGHABCD (32-bit halves swapped).
    await tester.enterText(
      find.byKey(const Key('hex.input')),
      '54 44 2D 18 40 09 21 FB',
    );
    await tester.pump();
    await reveal(tester, find.byKey(const Key('hex.customResult')), 'hex.view');
    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('hex.customResult')))
          .data,
      '3.141592653589793',
    );

    await reveal(tester, find.byKey(const Key('hex.encodeValue')), 'hex.view');
    await tester.enterText(find.byKey(const Key('hex.encodeValue')), '230,1');
    await tester.pump();
    expect(
      tester.widget<SelectableText>(find.byKey(const Key('hex.encoded'))).data,
      '4366 199A',
    );
    await tester.tap(find.byKey(const Key('hex.useAsInput')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(matrixCell('float32', 'abcd'));
    expect(textIn(tester, matrixCell('float32', 'abcd')), '230.1');
  });

  testWidgets('slave scan lists the responding units', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1100));
    await connectSimulator(tester);
    await openTools(tester, tab: 'Scanner');
    await tester.enterText(find.byKey(const Key('scanner.to')), '4');
    await tester.enterText(find.byKey(const Key('scanner.timeout')), '20');
    await tester.tap(find.byKey(const Key('scanner.start')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Unit 2'), findsOneWidget);
    expect(find.text('Unit 3'), findsNothing);
    expect(find.textContaining('4 / 4 · 2 found'), findsOneWidget);
    expect(find.textContaining('many Modbus TCP devices'), findsOneWidget);
  });

  testWidgets('register scan reports addresses and exceptions', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1100));
    await connectSimulator(tester);
    await openTools(tester, tab: 'Scanner');
    await tester.tap(find.text('Register range'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('scanner.from')), '41009');
    await tester.enterText(find.byKey(const Key('scanner.to')), '41012');
    await tester.enterText(find.byKey(const Key('scanner.timeout')), '20');
    await tester.tap(find.byKey(const Key('scanner.start')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('41010'), findsOneWidget);
    expect(find.textContaining('SERVER DEVICE FAILURE'), findsNWidgets(2));
    expect(find.text('41011'), findsOneWidget);
  });

  testWidgets('statistics count requests and can be reset', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1100));
    await connectSimulator(tester);
    for (final address in ['40001', '41001']) {
      await tester.enterText(find.byKey(const Key('request.address')), address);
      await tester.tap(find.byKey(const Key('request.read')));
      await tester.pumpAndSettle();
    }
    await openTools(tester, tab: 'Statistics');
    expect(find.text('Requests'), findsWidgets);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('FC03'), findsOneWidget);
    await tester.tap(find.byKey(const Key('statistics.reset')));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet.'), findsOneWidget);
  });

  testWidgets('trend plots selected map values', (tester) async {
    await tester.pumpModbusApp(size: const Size(1600, 1100));
    await connectSimulator(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final profileId = container.read(currentProfileIdProvider)!;
    await container.read(registerMapControllerProvider.notifier).importEntries(
      profileId,
      [
        RegisterMapEntry(
          id: 'v',
          table: RegisterTable.holdingRegisters,
          address: 52,
          format: NumericFormat(DataType.float32, ByteOrder.parse('ABCD')),
          label: 'Voltage',
        ),
      ],
    );
    await openTools(tester, tab: 'Trend');
    expect(
      find.text('Waiting for data – poll the register map.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('trend.entry.v')));
    await tester.pumpAndSettle();
    // Drive polling through the UI so the fake test clock advances.
    await tester.tap(find.byKey(const Key('trend.poll')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('trend.chart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trend.poll')));
    await tester.pumpAndSettle();
  });
}
