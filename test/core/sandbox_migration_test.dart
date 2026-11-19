import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/sandbox_migration.dart';

void main() {
  late Directory home;
  late Directory support;
  late List<List<String>> calls;
  late int readExitCode;
  const bundle = 'de.example.test';

  setUp(() {
    home = Directory.systemTemp.createTempSync('migration');
    support = Directory('${home.path}/Library/Application Support/$bundle');
    calls = [];
    readExitCode = 1; // domain does not exist yet
  });
  tearDown(() => home.deleteSync(recursive: true));

  Directory container() =>
      Directory('${home.path}/Library/Containers/$bundle/Data/Library');

  SandboxMigration migration() => SandboxMigration(
    home: home.path,
    bundleId: bundle,
    supportDirectory: support,
    runProcess: (cmd, args) async {
      calls.add([cmd, ...args]);
      return ProcessResult(0, args.first == 'read' ? readExitCode : 0, '', '');
    },
  );

  void writeOld(String relative, String content) {
    File('${container().path}/$relative')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('copies documents and imports settings once', () async {
    writeOld('Application Support/$bundle/connection_profiles.json', 'P');
    writeOld('Application Support/$bundle/register_maps.json', 'M');
    writeOld('Application Support/$bundle/ignore.tmp', 'x');
    writeOld('Preferences/$bundle.plist', '<plist/>');

    final migrated = await migration().run();
    expect(
      migrated,
      containsAll([
        'connection_profiles.json',
        'register_maps.json',
        '$bundle.plist',
      ]),
    );
    expect(
      File('${support.path}/connection_profiles.json').readAsStringSync(),
      'P',
    );
    expect(File('${support.path}/ignore.tmp').existsSync(), isFalse);
    expect(calls.last.take(3), ['defaults', 'import', bundle]);

    // Second start: nothing happens.
    calls.clear();
    expect(await migration().run(), isEmpty);
    expect(calls, isEmpty);
  });

  test('never overwrites newer data', () async {
    writeOld('Application Support/$bundle/connection_profiles.json', 'old');
    File('${support.path}/connection_profiles.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('new');
    writeOld('Preferences/$bundle.plist', '<plist/>');
    readExitCode = 0; // settings already exist

    expect(await migration().run(), isEmpty);
    expect(
      File('${support.path}/connection_profiles.json').readAsStringSync(),
      'new',
    );
    expect(calls.where((c) => c[1] == 'import'), isEmpty);
  });

  test('no container: only the marker is written', () async {
    expect(await migration().run(), isEmpty);
    expect(
      File('${support.path}/${SandboxMigration.markerName}').existsSync(),
      isTrue,
    );
  });
}
