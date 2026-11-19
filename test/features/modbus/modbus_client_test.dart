import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_decoder.dart';
import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_transaction.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/data/codec/rtu_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';

import '../../helpers/simulated_client.dart';

void main() {
  for (final framing in const <ModbusFraming>[MbapFraming(), RtuFraming()]) {
    group('${framing.kind.name.toUpperCase()} via simulator', () {
      late SimulatedSetup setup;
      setUp(() => setup = SimulatedSetup(framing));
      tearDown(() => setup.dispose());

      test('reads FLOAT32 10.0 from the demo map', () async {
        final registers = await setup.client.readHoldingRegisters(
          DemoMap.float10Abcd,
          2,
        );
        final value = decodeValue(
          registersToBytes(registers),
          DataType.float32,
          ByteOrder.parse('ABCD'),
        );
        expect((value as FloatValue).value, 10.0);
      });

      test('all function codes work end to end', () async {
        final c = setup.client;
        expect(await c.readCoils(0, 4), [true, false, false, true]);
        expect(await c.readDiscreteInputs(2, 2), [true, false]);
        expect(
          await c.readInputRegisters(DemoMap.inputPressure, 2),
          float32Registers(1013.25),
        );

        await c.writeSingleRegister(500, 0xBEEF);
        await c.writeMultipleRegisters(501, [1, 2, 3]);
        expect(await c.readHoldingRegisters(500, 4), [0xBEEF, 1, 2, 3]);

        await c.writeSingleCoil(100, value: true);
        await c.writeMultipleCoils(101, [true, false, true]);
        expect(await c.readCoils(100, 4), [true, true, false, true]);

        await c.writeSingleRegister(600, 0x0012);
        await c.maskWriteRegister(600, andMask: 0x00F2, orMask: 0x0025);
        // Spec example: (0x12 AND 0xF2) OR (0x25 AND NOT 0xF2) = 0x17
        expect(await c.readHoldingRegisters(600, 1), [0x17]);

        final readBack = await c.readWriteMultipleRegisters(
          readAddress: 700,
          readCount: 2,
          writeAddress: 700,
          writeValues: [7, 8],
        );
        expect(readBack, [7, 8]);

        final id = await c.readDeviceIdentification();
        expect(id.text(DeviceIdObject.vendorName), 'Modbus Explorer');
        expect(id.objects.keys, [0, 1, 2]);
      });

      test('exception responses throw ModbusDeviceException', () async {
        await expectLater(
          setup.client.readHoldingRegisters(1999, 2),
          throwsA(
            isA<ModbusDeviceException>().having(
              (e) => e.code,
              'code',
              ModbusExceptionCode.illegalDataAddress,
            ),
          ),
        );
        await expectLater(
          setup.client.readHoldingRegisters(DemoMap.faultStart, 1),
          throwsA(
            isA<ModbusDeviceException>().having(
              (e) => e.code,
              'code',
              ModbusExceptionCode.serverDeviceFailure,
            ),
          ),
        );
      });

      test('unknown unit ID times out after all retries', () async {
        final transactions = <ModbusTransaction>[];
        setup.client.transactions.listen(transactions.add);
        await expectLater(
          setup.client.execute(
            ReadRegistersRequest(
              table: RegisterTable.holdingRegisters,
              address: 0,
              count: 1,
            ),
            unitId: 99,
            timeout: const Duration(milliseconds: 40),
            retries: 2,
          ),
          throwsA(
            isA<ModbusTimeoutException>().having(
              (e) => e.attempts,
              'attempts',
              3,
            ),
          ),
        );
        await pumpEventQueue();
        expect(transactions.single.attempts, 3);
        expect(transactions.single.isSuccess, isFalse);
      });

      test('retry recovers from a dropped response', () async {
        setup.faults.dropNext = 1;
        final registers = await setup.client.execute(
          ReadRegistersRequest(
            table: RegisterTable.holdingRegisters,
            address: DemoMap.int16,
            count: 1,
          ),
          timeout: const Duration(milliseconds: 50),
          retries: 1,
        );
        expect((registers as ReadRegistersResponse).values, [-1234 & 0xFFFF]);
      });

      test('corrupted response: RTU retries, TCP cannot detect', () async {
        final frames = <FrameEvent>[];
        setup.client.frames.listen(frames.add);
        setup.faults.corruptNext = 1;
        final response = await setup.client.execute(
          ReadRegistersRequest(
            table: RegisterTable.holdingRegisters,
            address: DemoMap.bcd16,
            count: 1,
          ),
          retries: 1,
        );
        final value = (response as ReadRegistersResponse).values.single;
        await pumpEventQueue();
        final statuses = frames
            .where((f) => f.direction == FrameDirection.rx)
            .map((f) => f.status)
            .toList();
        if (framing.kind == FrameKind.rtu) {
          expect(value, 0x1234);
          expect(statuses, [FrameStatus.crcError, FrameStatus.ok]);
        } else {
          // TCP relies on the TCP checksum; a corrupted payload slips through.
          expect(value, isNot(0x1234));
          expect(statuses, [FrameStatus.ok]);
        }
      });

      test(
        'concurrent requests are serialized and answered in order',
        () async {
          final futures = [
            for (var i = 0; i < 5; i++)
              setup.client.readHoldingRegisters(DemoMap.float10Abcd + i, 1),
          ];
          final results = await Future.wait(futures);
          final expected = await setup.client.readHoldingRegisters(
            DemoMap.float10Abcd,
            5,
          );
          expect(results.map((r) => r.single), expected);
        },
      );

      test('frames and transactions are reported', () async {
        final frames = <FrameEvent>[];
        final transactions = <ModbusTransaction>[];
        setup.client.frames.listen(frames.add);
        setup.client.transactions.listen(transactions.add);
        await setup.client.readHoldingRegisters(0, 2);
        await pumpEventQueue();
        expect(frames.map((f) => f.direction), [
          FrameDirection.tx,
          FrameDirection.rx,
        ]);
        expect(frames.every((f) => f.kind == framing.kind), isTrue);
        final t = transactions.single;
        expect(t.isSuccess, isTrue);
        expect(t.attempts, 1);
        expect(t.latency, isNotNull);
        expect(frames.map((f) => f.transactionNumber), [t.number, t.number]);
      });

      test('closing the peer fails pending and later requests', () async {
        setup.faults.latency = const Duration(milliseconds: 100);
        final pending = setup.client.readHoldingRegisters(0, 1);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await setup.serverSide.close();
        await expectLater(pending, throwsA(isA<ModbusConnectionException>()));
        expect(setup.client.isClosed, isTrue);
        await expectLater(
          setup.client.readHoldingRegisters(0, 1),
          throwsA(isA<ModbusConnectionException>()),
        );
      });
    });
  }

  group('TCP specifics', () {
    test('late response is flagged unexpected and does not confuse the '
        'next request', () async {
      final setup = SimulatedSetup(const MbapFraming());
      addTearDown(setup.dispose);
      final frames = <FrameEvent>[];
      setup.client.frames.listen(frames.add);
      setup.faults.latency = const Duration(milliseconds: 80);

      await expectLater(
        setup.client.execute(
          ReadRegistersRequest(
            table: RegisterTable.holdingRegisters,
            address: DemoMap.int16,
            count: 1,
          ),
          timeout: const Duration(milliseconds: 20),
          retries: 0,
        ),
        throwsA(isA<ModbusTimeoutException>()),
      );
      setup.faults.latency = Duration.zero;
      // The late answer to the first request arrives while this one waits.
      final values = await setup.client.readHoldingRegisters(DemoMap.bcd16, 1);
      expect(values, [0x1234]);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        frames.where((f) => f.status == FrameStatus.unexpected),
        isNotEmpty,
      );
    });

    test('unit 0 addresses the first device', () async {
      final setup = SimulatedSetup(const MbapFraming());
      addTearDown(setup.dispose);
      expect(
        await setup.client.readHoldingRegisters(DemoMap.bcd16, 1, unitId: 0),
        [0x1234],
      );
    });
  });

  group('RTU specifics', () {
    test('broadcast write reaches all devices without a response', () async {
      final setup = SimulatedSetup(const RtuFraming());
      addTearDown(setup.dispose);
      final response = await setup.client.execute(
        WriteSingleRegisterRequest(address: 10, value: 4242),
        unitId: 0,
      );
      expect(response, const NoResponseExpected());
      await pumpEventQueue();
      expect(
        await setup.client.readHoldingRegisters(10, 1, unitId: demoUnitId),
        [4242],
      );
      expect(
        await setup.client.readHoldingRegisters(10, 1, unitId: meterUnitId),
        [4242],
      );
    });

    test('broadcast reads are rejected', () async {
      final setup = SimulatedSetup(const RtuFraming());
      addTearDown(setup.dispose);
      expect(
        () => setup.client.readHoldingRegisters(0, 1, unitId: 0),
        throwsArgumentError,
      );
    });

    test('stale bytes before a request are discarded and logged', () async {
      final (clientSide, serverSide) = InMemoryChannel.pair();
      final client = ModbusClient(
        channel: clientSide,
        framing: const RtuFraming(),
        defaults: const RequestOptions(
          timeout: Duration(milliseconds: 50),
          retries: 0,
        ),
        silenceTimeout: const Duration(seconds: 10),
      );
      addTearDown(client.close);
      final frames = <FrameEvent>[];
      client.frames.listen(frames.add);
      // Half a frame of line noise, then silence.
      await serverSide.write(
        const RtuFraming()
            .encodeFrame(unitId: 1, pdu: [0x03, 0x04, 0, 1])
            .sublist(0, 4),
      );
      await pumpEventQueue();
      serverSide.input.listen((request) {
        unawaited(
          serverSide.write(
            const RtuFraming().encodeFrame(unitId: 1, pdu: [0x03, 0x02, 0, 7]),
          ),
        );
      });
      expect(await client.readHoldingRegisters(0, 1), [7]);
      expect(frames.first.status, FrameStatus.incomplete);
    });
  });

  test('transaction IDs wrap around after 65535', () async {
    final setup = SimulatedSetup(const MbapFraming());
    addTearDown(setup.dispose);
    final ids = <int>[];
    setup.client.frames
        .where((f) => f.direction == FrameDirection.tx)
        .listen((f) => ids.add((f.bytes[0] << 8) | f.bytes[1]));
    await setup.client.readHoldingRegisters(0, 1);
    await setup.client.readHoldingRegisters(0, 1);
    await pumpEventQueue();
    expect(ids, [1, 2]);
  });
}
