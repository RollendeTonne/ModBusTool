import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/shared/profiles/profile_store.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

void main() {
  late InMemoryDocumentStore documents;
  late ProfileStore store;

  setUp(() {
    documents = InMemoryDocumentStore();
    store = ProfileStore(documents);
  });

  Map<String, Object?> doc() =>
      jsonDecode(documents.documents[ProfileStore.documentName]!)
          as Map<String, Object?>;

  test('modules never overwrite each other', () async {
    await store.save(ProtocolModule.modbus, [
      {'id': 'a', 'name': 'PLC'},
    ]);
    await store.save(ProtocolModule.mqtt, [
      {'id': 'b', 'name': 'Broker'},
    ]);
    await store.save(ProtocolModule.modbus, [
      {'id': 'c', 'name': 'Meter'},
    ]);
    expect((await store.load(ProtocolModule.modbus))!.map((e) => e['id']), [
      'c',
    ]);
    expect((await store.load(ProtocolModule.mqtt))!.single['module'], 'mqtt');
    expect(doc()['version'], 2);
    expect(doc()['modules'], ['modbus', 'mqtt']);
  });

  test('a module that never saved reports first start', () async {
    expect(await store.load(ProtocolModule.modbus), isNull);
    await store.save(ProtocolModule.modbus, const []);
    expect(await store.load(ProtocolModule.modbus), isEmpty);
    expect(await store.load(ProtocolModule.mqtt), isNull);
  });

  test('schema 1 files (Modbus only, no module field) still load', () async {
    documents.documents[ProfileStore.documentName] = jsonEncode({
      'version': 1,
      'profiles': [
        {'id': 'old', 'type': 'tcp'},
      ],
    });
    expect((await store.load(ProtocolModule.modbus))!.single['id'], 'old');
    expect(await store.load(ProtocolModule.mqtt), isNull);

    await store.save(ProtocolModule.mqtt, [
      {'id': 'b'},
    ]);
    // The old Modbus entry survives the upgrade to schema 2.
    expect((await store.load(ProtocolModule.modbus))!.single['id'], 'old');
  });

  test('corrupt file is empty, not first start', () async {
    documents.documents[ProfileStore.documentName] = '{oops';
    expect(await store.load(ProtocolModule.modbus), isEmpty);
  });
}
