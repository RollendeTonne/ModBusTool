import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/data/register_map_codec.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_page.dart';

/// Keeps the documented formats honest: the README examples must import.
void main() {
  test('README register map CSV example imports without errors', () {
    final readme = File('README.md').readAsStringSync();
    final match = RegExp(
      r'```\n(table;address;label.*?)```',
      dotAll: true,
    ).firstMatch(readme);
    expect(match, isNotNull, reason: 'CSV example not found in README');
    var id = 0;
    final result = registerMapFromCsv(match!.group(1)!, newId: () => '${id++}');
    expect(result.errors, isEmpty);
    expect(result.entries.map((e) => e.label), [
      'Spannung L1',
      'Temperatur',
      'Seriennummer',
      'Alarm',
      'Pumpe',
    ]);
    expect(result.entries[1].scaling.factor, 0.1);
    expect(result.entries[2].format, isA<TextFormat>());
    expect((result.entries[3].format as BitFormat).bit, 3);
  });

  test('version shown in the app matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+?)\+',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}
