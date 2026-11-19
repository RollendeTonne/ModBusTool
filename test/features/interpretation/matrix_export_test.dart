import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/matrix_export.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';

void main() {
  test('TSV export has header and formatted values', () {
    final text = matrixToDelimited(
      InterpretationMatrix.compute(const [0x4120, 0x0000]),
    );
    final lines = text.split('\n');
    expect(lines.first, 'Type\tABCD\tBADC\tCDAB\tDCBA');
    final float = lines.firstWhere((l) => l.startsWith('FLOAT32'));
    expect(float.split('\t')[1], '10.0');
    final float64 = lines.firstWhere((l) => l.startsWith('FLOAT64'));
    expect(float64, 'FLOAT64\t\t\t\t');
  });

  test('scaling applies to numeric cells', () {
    final text = matrixToDelimited(
      InterpretationMatrix.compute(const [215]),
      scaling: const Scaling(factor: 0.1),
      separator: csvSeparator,
    );
    expect(text.split('\n')[2], startsWith('UINT16;21.5;'));
  });

  test('quoteField only quotes when needed', () {
    expect(quoteField('abc', ';'), 'abc');
    expect(quoteField('a;b', ';'), '"a;b"');
    expect(quoteField('say "hi"', ';'), '"say ""hi"""');
    expect(quoteField('line\nbreak', '\t'), '"line\nbreak"');
  });

  test('parseDelimited handles quotes, empty fields and CRLF', () {
    expect(parseDelimited('a;"b;c";\r\n"x ""y""";;z\n\n'), [
      ['a', 'b;c', ''],
      ['x "y"', '', 'z'],
    ]);
    expect(parseDelimited('"multi\nline";2'), [
      ['multi\nline', '2'],
    ]);
  });
}
