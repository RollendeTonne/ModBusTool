import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/features/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/monitor/presentation/communication_log_controller.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';
import 'package:modbus_explorer/features/tools/presentation/scanner_controller.dart';
import 'package:modbus_explorer/features/tools/presentation/trend_controller.dart';

import '../../helpers/container.dart';

Future<ProviderContainer> connected({
  SimulatorFraming framing = SimulatorFraming.tcp,
}) async {
  // Start listening before the connection exists, like the app does.
  final container = createTestContainer()
    ..listen(communicationLogControllerProvider, (_, _) {})
    ..listen(statisticsControllerProvider, (_, _) {})
    ..listen(trendControllerProvider, (_, _) {});
  await container
      .read(connectionControllerProvider.notifier)
      .connect(
        ConnectionProfile(
          id: 'sim',
          name: 'Sim',
          config: SimulatorConnectionConfig(
            framing: framing,
            latency: Duration.zero,
          ),
          createdAt: DateTime.utc(2026),
        ),
      );
  return container;
}

Future<void> readOnce(ProviderContainer c, RegisterQuery q) async {
  c.read(registersControllerProvider.notifier).setQuery(q);
  await c.read(registersControllerProvider.notifier).read();
  // Frame/transaction streams deliver asynchronously after the response.
  await pumpEventQueue();
}

void main() {
  group('communication log', () {
    test('records TX/RX frames with their transaction', () async {
      final c = await connected();
      addTearDown(c.dispose);
      await readOnce(c, const RegisterQuery(count: 2));
      c.read(communicationLogControllerProvider.notifier).flush();
      final log = c.read(communicationLogControllerProvider);
      expect(log.frames.map((f) => f.direction), [
        FrameDirection.tx,
        FrameDirection.rx,
      ]);
      final number = log.frames.first.transactionNumber!;
      expect(log.transactions[number]!.isSuccess, isTrue);
    });

    test('pause drops frames and counts them; clear empties', () async {
      final c = await connected();
      addTearDown(c.dispose);
      final log = c.read(communicationLogControllerProvider.notifier)
        ..setPaused(paused: true);
      await readOnce(c, const RegisterQuery());
      log.flush();
      var state = c.read(communicationLogControllerProvider);
      expect(state.frames, isEmpty);
      expect(state.notRecorded, 2);

      log.setPaused(paused: false);
      await readOnce(c, const RegisterQuery());
      log.flush();
      state = c.read(communicationLogControllerProvider);
      expect(state.frames, hasLength(2));
      expect(state.notRecorded, 0);

      log.clear();
      expect(c.read(communicationLogControllerProvider).frames, isEmpty);
    });

    test('updates are batched and flushed automatically', () async {
      final c = await connected();
      addTearDown(c.dispose);
      await readOnce(c, const RegisterQuery());
      expect(c.read(communicationLogControllerProvider).frames, isEmpty);
      await Future<void>.delayed(CommunicationLogController.flushInterval * 2);
      expect(c.read(communicationLogControllerProvider).frames, hasLength(2));
    });

    test('statistics count errors independently of the log', () async {
      final c = await connected();
      addTearDown(c.dispose);
      c
          .read(communicationLogControllerProvider.notifier)
          .setPaused(paused: true);
      await readOnce(c, const RegisterQuery());
      await readOnce(c, const RegisterQuery(address: DemoMap.faultStart));
      final stats = c.read(statisticsControllerProvider);
      expect(stats.requests, 2);
      expect(stats.deviceExceptions, 1);
      expect(stats.latencyAverage, isNotNull);
      c.read(statisticsControllerProvider.notifier).reset();
      expect(c.read(statisticsControllerProvider).requests, 0);
    });
  });

  group('scanner', () {
    for (final framing in SimulatorFraming.values) {
      test('slave scan finds unit 1 and 2 ($framing)', () async {
        final c = await connected(framing: framing);
        addTearDown(c.dispose);
        await c
            .read(scannerControllerProvider.notifier)
            .scanSlaves(
              from: 1,
              to: 6,
              table: RegisterTable.holdingRegisters,
              address: 0,
              timeout: const Duration(milliseconds: 30),
            );
        final state = c.read(scannerControllerProvider);
        expect(state.isRunning, isFalse);
        expect(state.done, 6);
        expect(state.hits.map((h) => h.key), [1, 2]);
        expect(state.hits.first.value, isNotNull);
      });
    }

    test('an exception answer still counts as present', () async {
      final c = await connected();
      addTearDown(c.dispose);
      await c
          .read(scannerControllerProvider.notifier)
          .scanSlaves(
            from: 1,
            to: 2,
            table: RegisterTable.holdingRegisters,
            address: 500, // beyond the meter's 100 registers
            timeout: const Duration(milliseconds: 30),
          );
      final hits = c.read(scannerControllerProvider).hits;
      expect(hits.map((h) => h.key), [1, 2]);
      expect(hits[1].exceptionCode, 2);
    });

    test('register scan skips gaps and fault ranges via fallback', () async {
      final c = await connected();
      addTearDown(c.dispose);
      await c
          .read(scannerControllerProvider.notifier)
          .scanRegisters(
            table: RegisterTable.holdingRegisters,
            from: 1995,
            to: 2004,
            timeout: const Duration(milliseconds: 30),
            blockSize: 4,
          );
      var state = c.read(scannerControllerProvider);
      expect(state.done, 10);
      expect(state.hits.map((h) => h.key), [1995, 1996, 1997, 1998, 1999]);

      await c
          .read(scannerControllerProvider.notifier)
          .scanRegisters(
            table: RegisterTable.holdingRegisters,
            from: 998,
            to: 1011,
            timeout: const Duration(milliseconds: 30),
            blockSize: 5,
          );
      state = c.read(scannerControllerProvider);
      // 1000..1009 answer with exception 04, which is reported.
      final exceptions = state.hits.where((h) => h.exceptionCode == 4);
      expect(exceptions.map((h) => h.key), [
        for (var a = 1000; a <= 1009; a++) a,
      ]);
      expect(state.hits.where((h) => h.value != null).map((h) => h.key), [
        998,
        999,
        1010,
        1011,
      ]);
    });

    test('cancel stops the scan', () async {
      final c = await connected();
      addTearDown(c.dispose);
      final scanner = c.read(scannerControllerProvider.notifier);
      final running = scanner.scanSlaves(
        from: 3,
        to: 247,
        table: RegisterTable.holdingRegisters,
        address: 0,
        timeout: const Duration(milliseconds: 20),
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
      scanner.cancel();
      await running;
      final state = c.read(scannerControllerProvider);
      expect(state.cancelled, isTrue);
      expect(state.isRunning, isFalse);
      expect(state.done, lessThan(245));
    });

    test('scanning without connection reports an error', () async {
      final c = createTestContainer();
      addTearDown(c.dispose);
      await c
          .read(scannerControllerProvider.notifier)
          .scanSlaves(
            from: 1,
            to: 2,
            table: RegisterTable.holdingRegisters,
            address: 0,
            timeout: const Duration(milliseconds: 20),
          );
      expect(c.read(scannerControllerProvider).error, isA<NotConnectedError>());
    });
  });

  test('trend records scaled numeric map values', () async {
    final c = await connected();
    addTearDown(c.dispose);
    await c.read(registerMapControllerProvider.future);
    await c.read(registerMapControllerProvider.notifier).importEntries('sim', [
      RegisterMapEntry(
        id: 'ten',
        table: RegisterTable.holdingRegisters,
        address: DemoMap.float10Abcd,
        format: NumericFormat(DataType.float32, ByteOrder.parse('ABCD')),
        scaling: const Scaling(factor: 2),
      ),
      RegisterMapEntry(
        id: 'text',
        table: RegisterTable.holdingRegisters,
        address: DemoMap.text,
        format: TextFormat(registerCount: 8),
      ),
    ]);
    final trend = c.read(trendControllerProvider.notifier);
    expect(trend.toggle('ten'), isTrue);
    await c.read(mapValuesControllerProvider.notifier).read();
    await c.read(mapValuesControllerProvider.notifier).read();
    final state = c.read(trendControllerProvider);
    expect(state.series['ten']!.map((p) => p.value), [20, 20]);
    expect(state.series.containsKey('text'), isFalse);

    for (final id in ['a', 'b', 'c']) {
      expect(trend.toggle(id), isTrue);
    }
    expect(trend.toggle('d'), isFalse, reason: 'max 4 series');
    trend.clear();
    expect(c.read(trendControllerProvider).series, isEmpty);
    expect(c.read(trendControllerProvider).selected, hasLength(4));
  });
}
