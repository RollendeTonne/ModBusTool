import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_json.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_repository.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/shared/profiles/profile_store.dart';

final created = DateTime.utc(2026, 1, 2, 3, 4, 5);

final samples = [
  ConnectionProfile(
    id: 'tcp',
    name: 'PLC',
    createdAt: created,
    lastUsedAt: DateTime.utc(2026, 2),
    autoReconnect: true,
    config: const TcpConnectionConfig(
      host: '192.168.0.10',
      port: 5020,
      options: RequestOptions(
        unitId: 17,
        timeout: Duration(milliseconds: 750),
        retries: 3,
      ),
    ),
  ),
  ConnectionProfile(
    id: 'gw',
    name: 'Gateway',
    createdAt: created,
    config: const RtuOverTcpConnectionConfig(host: 'gw.local'),
  ),
  ConnectionProfile(
    id: 'rtu',
    name: 'Meter',
    createdAt: created,
    config: const RtuConnectionConfig(
      serial: SerialSettings(
        portName: '/dev/ttyUSB0',
        baudRate: 250000,
        dataBits: 7,
        parity: SerialParity.odd,
        stopBits: 2,
        rts: SerialLineMode.on,
        dtr: SerialLineMode.off,
        interFrameDelay: Duration(microseconds: 2500),
      ),
    ),
  ),
  ConnectionProfile(
    id: 'sim',
    name: 'Sim',
    createdAt: created,
    config: const SimulatorConnectionConfig(
      framing: SimulatorFraming.rtu,
      latency: Duration(milliseconds: 20),
      dropProbability: 0.05,
      corruptProbability: 0.125,
    ),
  ),
];

void main() {
  group('profile JSON', () {
    for (final profile in samples) {
      test('round-trips ${profile.config.kind.name}', () {
        final json = jsonDecode(jsonEncode(profileToJson(profile)));
        expect(profileFromJson(json as Map<String, Object?>), profile);
      });
    }

    test('document carries the schema version', () {
      expect(profilesToJson(samples)['version'], profilesSchemaVersion);
    });

    test('broken entries are skipped, valid ones kept', () {
      final json = profilesToJson(samples);
      (json['profiles']! as List).insert(1, {'id': 'x', 'type': 'warp'});
      final parsed = profilesFromJson(jsonDecode(jsonEncode(json)));
      expect(parsed.map((p) => p.id), ['tcp', 'gw', 'rtu', 'sim']);
    });

    test('garbage yields an empty list', () {
      expect(profilesFromJson(null), isEmpty);
      expect(profilesFromJson('nope'), isEmpty);
      expect(profilesFromJson({'profiles': 3}), isEmpty);
    });

    test('optional serial fields default sensibly', () {
      final json = profileToJson(samples[2]);
      final serial = json['serial']! as Map<String, Object?>
        ..remove('rts')
        ..remove('dtr')
        ..remove('interFrameDelayUs');
      json['serial'] = serial;
      final config = profileFromJson(json).config as RtuConnectionConfig;
      expect(config.serial.rts, SerialLineMode.unchanged);
      expect(config.serial.interFrameDelay, isNull);
    });
  });

  group('ProfileRepository', () {
    test('null on first start, list after saving', () async {
      final store = InMemoryDocumentStore();
      final repository = ProfileRepository(ProfileStore(store));
      expect(await repository.load(), isNull);
      await repository.save(samples);
      expect(await repository.load(), samples);
      expect(store.documents[ProfileStore.documentName], contains('\n  '));
    });

    test('corrupt file yields an empty list instead of crashing', () async {
      final repository = ProfileRepository(
        ProfileStore(
          InMemoryDocumentStore({ProfileStore.documentName: '{oops'}),
        ),
      );
      expect(await repository.load(), isEmpty);
    });
  });

  test('summary is compact and technical', () {
    expect(samples[0].config.summary, '192.168.0.10:5020 · ID 17');
    expect(samples[2].config.summary, '/dev/ttyUSB0 250000 7O2 · ID 1');
    expect(samples[3].config.summary, 'RTU · ID 1');
  });
}
