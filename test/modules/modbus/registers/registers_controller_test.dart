import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/modules/modbus/registers/domain/register_snapshot.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/modules/modbus/simulator/domain/demo_devices.dart';

import '../../../helpers/container.dart';

Future<(ProviderContainer, SimulatorBank)> connectedContainer() async {
  final bank = SimulatorBank.demo();
  final container = createTestContainer(bank: bank);
  await container
      .read(connectionControllerProvider.notifier)
      .connect(
        ConnectionProfile(
          id: 's',
          name: 'Sim',
          config: const SimulatorConnectionConfig(latency: Duration.zero),
          createdAt: DateTime.utc(2026),
        ),
      );
  return (container, bank);
}

void main() {
  group('RegisterSnapshot', () {
    final t0 = DateTime.utc(2026);
    final t1 = t0.add(const Duration(seconds: 1));
    final first = RegisterSnapshot.initial(
      table: RegisterTable.holdingRegisters,
      start: 10,
      values: const [1, 2, 3],
      readAt: t0,
    );

    test('marks only changed values with the new timestamp', () {
      final second = first.next(
        [1, 5, 3],
        t1,
        table: RegisterTable.holdingRegisters,
        start: 10,
      );
      expect(second.changedAt, [null, t1, null]);
      final third = second.next(
        [1, 5, 4],
        t1.add(const Duration(seconds: 1)),
        table: RegisterTable.holdingRegisters,
        start: 10,
      );
      expect(third.changedAt[1], t1, reason: 'earlier change is kept');
      expect(third.changedAt[2], isNotNull);
    });

    test('a different range starts fresh', () {
      final moved = first.next(
        [9, 9, 9],
        t1,
        table: RegisterTable.holdingRegisters,
        start: 11,
      );
      expect(moved.changedAt, everyElement(isNull));
      expect(moved.start, 11);
    });

    test('lookup helpers', () {
      expect(first.covers(RegisterTable.holdingRegisters, 12), isTrue);
      expect(first.covers(RegisterTable.holdingRegisters, 13), isFalse);
      expect(first.covers(RegisterTable.inputRegisters, 10), isFalse);
      expect(first.valueAt(11), 2);
      expect(first.valueAt(9), isNull);
    });
  });

  group('RegistersController', () {
    test('read without connection reports NotConnectedError', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(registersControllerProvider.notifier)
          .read();
      expect(ok, isFalse);
      expect(
        container.read(registersControllerProvider).lastError,
        isA<NotConnectedError>(),
      );
    });

    test('reads registers and detects changes between reads', () async {
      final (container, bank) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery(address: DemoMap.int16, count: 3));
      expect(await controller.read(), isTrue);
      var snapshot = container.read(registersControllerProvider).snapshot!;
      expect(snapshot.values, [-1234 & 0xFFFF, 0x1234, 0]);
      expect(snapshot.changedAt, everyElement(isNull));

      bank.devices[demoUnitId]!.holdingRegisters[DemoMap.bcd16] = 0x9999;
      await controller.read();
      snapshot = container.read(registersControllerProvider).snapshot!;
      expect(snapshot.values[1], 0x9999);
      expect(snapshot.changedAt[1], isNotNull);
      expect(snapshot.changedAt[0], isNull);
    });

    test('bit tables are read as 0/1', () async {
      final (container, _) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(
          const RegisterQuery(table: RegisterTable.coils, address: 1, count: 3),
        );
      await controller.read();
      expect(container.read(registersControllerProvider).snapshot!.values, [
        0,
        0,
        1,
      ]);
    });

    test('count is clamped to the protocol limit', () {
      final container = createTestContainer();
      addTearDown(container.dispose);
      container
          .read(registersControllerProvider.notifier)
          .setQuery(const RegisterQuery(count: 500));
      expect(container.read(registersControllerProvider).query.count, 125);
    });

    test('device exceptions are stored as lastError', () async {
      final (container, _) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery(address: DemoMap.faultStart, count: 1));
      expect(await controller.read(), isFalse);
      final state = container.read(registersControllerProvider);
      expect(state.lastError, isA<ModbusDeviceException>());
      expect(state.errorCount, 1);
    });

    test('polling repeats and stops when disconnected', () async {
      final (container, _) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setPollInterval(const Duration(milliseconds: 50))
        ..startPolling();
      expect(container.read(registersControllerProvider).isPolling, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 280));
      expect(
        container.read(registersControllerProvider).readCount,
        greaterThanOrEqualTo(3),
      );
      await container.read(connectionControllerProvider.notifier).disconnect();
      expect(container.read(registersControllerProvider).isPolling, isFalse);
      controller.stopPolling();
    });

    test('writes are blocked until unlocked, then re-read', () async {
      final (container, _) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setQuery(const RegisterQuery(address: 300, count: 2));
      await controller.read();
      final request = WriteSingleRegisterRequest(address: 301, value: 42);
      await expectLater(controller.write(request), throwsStateError);

      controller.setWriteUnlocked(unlocked: true);
      await controller.write(request);
      final snapshot = container.read(registersControllerProvider).snapshot!;
      expect(snapshot.values, [0, 42]);
      expect(snapshot.changedAt[1], isNotNull);
    });

    test('read requests are rejected as writes', () async {
      final (container, _) = await connectedContainer();
      addTearDown(container.dispose);
      final controller = container.read(registersControllerProvider.notifier)
        ..setWriteUnlocked(unlocked: true);
      expect(
        () => controller.write(
          ReadRegistersRequest(
            table: RegisterTable.holdingRegisters,
            address: 0,
            count: 1,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
