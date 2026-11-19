import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/data/register_map_repository.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/interpretation_input.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/modules/modbus/simulator/domain/demo_devices.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';

import '../../../helpers/container.dart';

final profile = ConnectionProfile(
  id: 'sim',
  name: 'Sim',
  config: const SimulatorConnectionConfig(latency: Duration.zero),
  createdAt: DateTime.utc(2026),
);

RegisterMapEntry entry(
  String id,
  int address,
  DataType type,
  String order, {
  RegisterTable table = RegisterTable.holdingRegisters,
}) => RegisterMapEntry(
  id: id,
  table: table,
  address: address,
  format: NumericFormat(type, ByteOrder.parse(order)),
  label: id,
);

Future<(ProviderContainer, SimulatorBank, InMemoryDocumentStore)>
connected() async {
  final bank = SimulatorBank.demo();
  final documents = InMemoryDocumentStore();
  final container = createTestContainer(bank: bank, documents: documents);
  await container.read(connectionControllerProvider.notifier).connect(profile);
  await container.read(registerMapControllerProvider.future);
  return (container, bank, documents);
}

void main() {
  group('selection and interpretation input', () {
    test('single selection feeds 4 registers into the matrix', () async {
      final (container, _, _) = await connected();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery());
      await controller.read();
      controller.select(2);
      final input = container.read(interpretationInputProvider)!;
      expect(input.start, 2);
      expect(input.selectionLength, 1);
      expect(input.registers, hasLength(4));
      final matrix = container.read(interpretationMatrixProvider)!;
      final float = matrix.rows.firstWhere((r) => r.type == DataType.float32);
      // DemoMap 2..3 holds 10.0 in CDAB.
      expect((float.cells[2]!.value as FloatValue).value, 10.0);
    });

    test('shift-extend selects a range in either direction', () async {
      final (container, _, _) = await connected();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery(address: 30));
      await controller.read();
      controller
        ..select(37)
        ..select(30, extend: true);
      final input = container.read(interpretationInputProvider)!;
      expect((input.start, input.end), (30, 37));
      expect(input.selected, hasLength(8));
    });

    test('selection near the end is clamped to the read range', () async {
      final (container, _, _) = await connected();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery(count: 3));
      await controller.read();
      controller.select(2);
      expect(
        container.read(interpretationInputProvider)!.registers,
        hasLength(1),
      );
      controller.select(50);
      expect(container.read(interpretationInputProvider)!.start, 0);
    });

    test('bit tables and table changes', () async {
      final (container, _, _) = await connected();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..select(3)
        ..setQuery(const RegisterQuery(table: RegisterTable.coils));
      expect(
        container.read(registersControllerProvider).selectionStart,
        isNull,
      );
      await controller.read();
      expect(container.read(interpretationInputProvider), isNull);
    });
  });

  group('register map', () {
    test('entries are stored per profile and persisted', () async {
      final (container, _, documents) = await connected();
      addTearDown(container.dispose);
      final controller = container.read(registerMapControllerProvider.notifier);
      await controller.saveEntry(
        'sim',
        entry('b', 20, DataType.uint32, 'ABCD'),
      );
      await controller.saveEntry(
        'sim',
        entry('a', 0, DataType.float32, 'ABCD'),
      );
      await controller.saveEntry('other', entry('x', 5, DataType.uint16, 'AB'));
      expect(container.read(currentMapEntriesProvider).map((e) => e.id), [
        'a',
        'b',
      ]);
      await controller.saveEntry(
        'sim',
        entry('a', 0, DataType.float32, 'ABCD').copyWith(label: 'renamed'),
      );
      expect(container.read(currentMapEntriesProvider).first.label, 'renamed');

      final reloaded = await RegisterMapRepository(documents).load();
      expect(reloaded['sim']!.map((e) => e.id), ['a', 'b']);
      expect(reloaded['other']!.single.id, 'x');
      final json = jsonDecode(documents.documents['register_maps.json']!);
      expect((json as Map)['version'], 1);

      await controller.deleteEntry('sim', 'a');
      await controller.importEntries('sim', [
        entry('n', 9, DataType.int16, 'AB'),
      ], replace: true);
      expect(container.read(currentMapEntriesProvider).map((e) => e.id), ['n']);
    });

    test('map values are read in blocks; failing blocks only affect their '
        'entries', () async {
      final (container, bank, _) = await connected();
      addTearDown(container.dispose);
      final maps = container.read(registerMapControllerProvider.notifier);
      await maps.importEntries('sim', [
        entry('ten', DemoMap.float10Abcd, DataType.float32, 'ABCD'),
        entry('cdab', DemoMap.float10Cdab, DataType.float32, 'CDAB'),
        entry('fault', DemoMap.faultStart, DataType.uint16, 'AB'),
        entry(
          'temp',
          DemoMap.inputTemperature,
          DataType.float32,
          'ABCD',
          table: RegisterTable.inputRegisters,
        ),
        RegisterMapEntry(
          id: 'coil',
          table: RegisterTable.coils,
          address: 3,
          format: BitFormat(),
        ),
      ]);
      final controller = container.read(mapValuesControllerProvider.notifier);
      expect(await controller.read(), isFalse);
      var state = container.read(mapValuesControllerProvider);
      expect((state.values['ten']!.value as FloatValue).value, 10.0);
      expect((state.values['cdab']!.value as FloatValue).value, 10.0);
      expect(state.values['temp']!.value, isA<FloatValue>());
      expect(state.values['coil']!.value, const BoolValue(true));
      expect(state.errors['fault'], isA<ModbusDeviceException>());
      expect(state.lastError, isNull, reason: 'other blocks succeeded');

      bank.devices[demoUnitId]!.holdingRegisters[DemoMap.float10Abcd] = 0x4248;
      await controller.read();
      state = container.read(mapValuesControllerProvider);
      expect((state.values['ten']!.value as FloatValue).value, 50.0);
      expect(state.values['ten']!.changedAt, isNotNull);
      expect(state.values['cdab']!.changedAt, isNull);
    });

    test('reading without connection reports NotConnectedError', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(mapValuesControllerProvider.notifier).read();
      expect(
        container.read(mapValuesControllerProvider).lastError,
        isA<NotConnectedError>(),
      );
    });
  });
}
