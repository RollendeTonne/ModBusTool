import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';

void main() {
  test('CSV gets a BOM, other types do not; stripBom reverses it', () {
    final csv = withBomFor(ExchangeFileType.csv, 'a;b');
    expect(csv.codeUnitAt(0), 0xFEFF);
    expect(stripBom(csv), 'a;b');
    expect(withBomFor(ExchangeFileType.json, '{}'), '{}');
    expect(stripBom('plain'), 'plain');
  });

  test('timestamped file names sort chronologically', () {
    expect(
      timestampedFileName('modbus-log', 'csv', DateTime(2026, 3, 4, 5, 6)),
      'modbus-log_2026-03-04_0506.csv',
    );
  });

  test('opened file extension', () {
    expect(const OpenedTextFile(name: 'Map.CSV', content: '').extension, 'csv');
    expect(const OpenedTextFile(name: 'noext', content: '').extension, '');
  });

  test('type groups carry extension, MIME type and UTI', () {
    final group = ExchangeFileType.json.typeGroup;
    expect(group.extensions, ['json']);
    expect(group.uniformTypeIdentifiers, ['public.json']);
  });
}
