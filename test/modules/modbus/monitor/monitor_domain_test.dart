import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/monitor/domain/communication_statistics.dart';
import 'package:modbus_explorer/modules/modbus/monitor/domain/log_export.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/frame_event.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_transaction.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_response.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';

import '../../../helpers/hex.dart';

ModbusTransaction transaction({
  ModbusRequest? request,
  ModbusError? error,
  int ms = 10,
  int attempts = 1,
  bool hasLatency = true,
}) => ModbusTransaction(
  number: 1,
  unitId: 1,
  request:
      request ??
      ReadRegistersRequest(
        table: RegisterTable.holdingRegisters,
        address: 0,
        count: 1,
      ),
  startedAt: DateTime(2026),
  duration: Duration(milliseconds: ms),
  attempts: attempts,
  latency: hasLatency ? Duration(milliseconds: ms) : null,
  response: error == null ? ReadRegistersResponse(const [1]) : null,
  error: error,
);

FrameEvent frame(
  String bytes, {
  FrameDirection direction = FrameDirection.tx,
  FrameKind kind = FrameKind.tcp,
  FrameStatus status = FrameStatus.ok,
}) => FrameEvent(
  timestamp: DateTime(2026, 1, 2, 3, 4, 5, 67),
  direction: direction,
  kind: kind,
  bytes: Uint8List.fromList(hex(bytes)),
  status: status,
  transactionNumber: 7,
);

void main() {
  group('CommunicationStatistics', () {
    test('aggregates counts, errors and latency', () {
      var stats = CommunicationStatistics(since: DateTime(2026));
      stats = stats
          .add(transaction())
          .add(transaction(ms: 30, attempts: 3))
          .add(
            transaction(
              error: ModbusDeviceException(functionCode: 3, exceptionCode: 2),
              ms: 20,
            ),
          )
          .add(
            transaction(
              error: ModbusTimeoutException(
                timeout: const Duration(seconds: 1),
                attempts: 2,
              ),
              hasLatency: false,
              attempts: 2,
            ),
          )
          .add(
            transaction(
              request: WriteSingleRegisterRequest(address: 0, value: 1),
              error: const ModbusProtocolException('CRC'),
              hasLatency: false,
            ),
          );
      expect(stats.requests, 5);
      expect(stats.successes, 2);
      expect(stats.errors, 3);
      expect(stats.errorRate, closeTo(0.6, 1e-9));
      expect(stats.deviceExceptions, 1);
      expect(stats.timeouts, 1);
      expect(stats.protocolErrors, 1);
      expect(stats.retries, 3);
      expect(stats.latencyMin, const Duration(milliseconds: 10));
      expect(stats.latencyMax, const Duration(milliseconds: 30));
      expect(stats.latencyAverage, const Duration(milliseconds: 20));
      expect(stats.byFunction['FC03']!.requests, 4);
      expect(stats.byFunction['FC03']!.errors, 2);
      expect(stats.byFunction['FC06']!.errors, 1);
    });

    test('empty statistics', () {
      final stats = CommunicationStatistics(since: DateTime(2026));
      expect(stats.errorRate, 0);
      expect(stats.latencyAverage, isNull);
    });
  });

  group('log export', () {
    test('frame line', () {
      expect(
        frameToLine(
          frame('00 01 00 00 00 06 01 03 00 00 00 0A'),
          latency: const Duration(milliseconds: 12),
        ),
        '03:04:05.067  TX  TCP  #7  FC03  [12]  '
        '00 01 00 00 00 06 01 03 00 00 00 0A  OK  12 ms',
      );
    });

    test('function labels and error detection', () {
      final exception = frame(
        '00 01 00 00 00 03 01 83 02',
        direction: FrameDirection.rx,
      );
      expect(frameFunctionLabel(exception), 'FC83');
      expect(frameBaseFunctionCode(exception), 3);
      expect(frameIsError(exception), isTrue);
      final crc = frame(
        '01 03 02 00 07 00 00',
        direction: FrameDirection.rx,
        kind: FrameKind.rtu,
        status: FrameStatus.crcError,
      );
      expect(frameIsError(crc), isTrue);
      expect(
        frameIsError(frame('00 01 00 00 00 06 01 03 00 00 00 0A')),
        isFalse,
      );
      expect(frameFunctionLabel(frame('')), '—');
    });

    test('CSV with header and quoting', () {
      final csv = framesToCsv([
        frame('00 01 00 00 00 06 01 03 00 00 00 0A'),
      ], latencyOf: (_) => const Duration(milliseconds: 5));
      final lines = csv.split('\n');
      expect(lines.first, logCsvColumns.join(';'));
      expect(lines[1], contains(';tx;tcp;7;FC03;12;ok;5;00 01 00'));
    });
  });
}
