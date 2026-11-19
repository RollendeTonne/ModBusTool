import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/presentation/matrix_table.dart';

typedef Action = (DataType, String, MatrixCellAction);

Future<List<Action>> pumpMatrix(
  WidgetTester tester,
  List<int> registers, {
  Scaling scaling = Scaling.identity,
  bool highlightPlausible = true,
}) async {
  final actions = <Action>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: supportedAppLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InterpretationMatrixTable(
            matrix: InterpretationMatrix.compute(registers),
            scaling: scaling,
            highlightPlausible: highlightPlausible,
            onCellAction: (row, cell, action) =>
                actions.add((row.type, cell.order.pattern, action)),
          ),
        ),
      ),
    ),
  );
  return actions;
}

Finder cell(DataType type, String family) =>
    find.byKey(Key('matrix.${type.name}.$family'));

Text textOf(WidgetTester tester, Finder cellFinder) => tester.widget<Text>(
  find.descendant(of: cellFinder, matching: find.byType(Text)),
);

void main() {
  testWidgets('shows every data type and byte order', (tester) async {
    await pumpMatrix(tester, [0x4120, 0x0000, 0x0000, 0x0000]);
    for (final header in ['ABCD', 'BADC', 'CDAB', 'DCBA']) {
      expect(find.text(header), findsOneWidget);
    }
    for (final type in InterpretationMatrix.defaultTypes) {
      expect(find.text(type.technicalName), findsOneWidget);
    }
    expect(textOf(tester, cell(DataType.float32, 'abcd')).data, '10.0');
    expect(textOf(tester, cell(DataType.uint16, 'badc')).data, '8257');
    expect(textOf(tester, cell(DataType.uint32, 'abcd')).data, '1092616192');
  });

  testWidgets('plausible values are emphasised, implausible ones dimmed', (
    tester,
  ) async {
    await pumpMatrix(tester, [0x4120, 0x0000]);
    final plausible = textOf(tester, cell(DataType.float32, 'abcd')).style!;
    expect(plausible.fontWeight, FontWeight.w700);
    expect(plausible.color, AppColors.light.plausible);

    // CDAB of 10.0 is a denormal float.
    final implausible = textOf(tester, cell(DataType.float32, 'cdab')).style!;
    expect(implausible.fontStyle, FontStyle.italic);
    expect(implausible.color, AppColors.light.implausible);
  });

  testWidgets('highlighting can be switched off', (tester) async {
    await pumpMatrix(tester, [0x4120, 0x0000], highlightPlausible: false);
    final style = textOf(tester, cell(DataType.float32, 'abcd')).style!;
    expect(style.fontWeight, isNot(FontWeight.w700));
  });

  testWidgets('types wider than the data show a placeholder', (tester) async {
    await pumpMatrix(tester, [0x4120, 0x0000]);
    expect(cell(DataType.float64, 'abcd'), findsNothing);
    expect(find.text('—'), findsNWidgets(4 * 4)); // 4 64-bit types × 4
  });

  testWidgets('duplicate 16-bit columns are faded', (tester) async {
    await pumpMatrix(tester, [0x1234]);
    expect(
      find.ancestor(
        of: textFinderIn(cell(DataType.uint16, 'cdab')),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: textFinderIn(cell(DataType.uint16, 'abcd')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('scaling is applied to numeric cells', (tester) async {
    await pumpMatrix(tester, [215], scaling: const Scaling(factor: 0.1));
    expect(textOf(tester, cell(DataType.int16, 'abcd')).data, '21.5');
  });

  testWidgets('tap copies, context menu offers add to map', (tester) async {
    final actions = await pumpMatrix(tester, [0x4120, 0x0000]);
    await tester.tap(cell(DataType.float32, 'abcd'));
    expect(actions.single, (DataType.float32, 'ABCD', MatrixCellAction.copy));

    await tester.tap(
      cell(DataType.int32, 'cdab'),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to register map…'));
    await tester.pumpAndSettle();
    expect(actions.last, (DataType.int32, 'CDAB', MatrixCellAction.addToMap));
  });

  testWidgets('tooltip explains byte order and plausibility', (tester) async {
    await pumpMatrix(tester, [0x4120, 0x0000]);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(
        of: textFinderIn(cell(DataType.float32, 'cdab')),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tooltip.message, contains('CDAB · 00 00 41 20'));
    expect(tooltip.message, contains('Denormalized'));
  });
}

Finder textFinderIn(Finder parent) =>
    find.descendant(of: parent, matching: find.byType(Text));
