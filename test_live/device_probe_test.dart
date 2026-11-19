// Live, READ-ONLY checks against a real device. Not part of `flutter test`
// (lives outside test/). Run explicitly:
//   MODBUS_HOST=<device-ip> flutter test test_live/device_probe_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/data/channel/socket_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/known_ports.dart';

final String host = Platform.environment['MODBUS_HOST'] ?? '';

void log(String s) => stdout.writeln('LIVE $s');

void main() {
  if (host.isEmpty) return;

  test('network scan of the single host', () async {
    final hosts = await const NetworkScanner().run(
      NetworkScanConfig(
        range: Ipv4Range.parse(host),
        ports: defaultScanPorts,
        modbusPorts: defaultModbusPorts,
        timeout: const Duration(milliseconds: 800),
      ),
      onProgress: (_, _, _) {},
      onHost: (_) {},
      isCancelled: () => false,
    );
    for (final h in hosts) {
      log(
        'scan: ${h.address} name=${h.hostname} mac=${h.mac} '
        'open=${h.openPorts} modbus=${h.modbus?.summary} '
        'exc=${h.modbus?.exceptionCode}',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('device identification and reads', () async {
    final client = ModbusClient(
      channel: await SocketChannel.connect(host, 502),
      framing: const MbapFraming(),
      defaults: const RequestOptions(timeout: Duration(seconds: 2)),
    );
    addTearDown(client.close);

    for (final category in DeviceIdCategory.values.take(3)) {
      try {
        final id = await client.readDeviceIdentification(category: category);
        final objects = id.objects.map(
          (k, v) => MapEntry(k, String.fromCharCodes(v)),
        );
        log('deviceId ${category.name}: $objects');
      } on ModbusError catch (e) {
        log('deviceId ${category.name}: $e');
      }
    }

    // Janitza UMG float area (manufacturer address lists start at 19000).
    for (final (fc, start) in [('03', 19000), ('04', 19000), ('03', 0)]) {
      try {
        final w = Stopwatch()..start();
        final regs = fc == '03'
            ? await client.readHoldingRegisters(start, 20)
            : await client.readInputRegisters(start, 20);
        log(
          'FC$fc $start x20 (${w.elapsedMilliseconds} ms): '
          '${regs.map((r) => formatHex(r, prefix: false)).join(' ')}',
        );
        if (fc == '03' && start == 19000) {
          for (var i = 0; i + 1 < regs.length; i += 2) {
            final m = InterpretationMatrix.compute(
              regs.sublist(i, i + 2),
              types: const [DataType.float32],
            );
            final cells = m.rows.single.cells;
            final text = [
              for (final c in cells)
                if (c != null) _cellText(c),
            ].join('  ');
            log('  ${start + i}: $text');
          }
        }
      } on ModbusError catch (e) {
        log('FC$fc $start: $e');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

String _cellText(MatrixCell c) {
  final mark = c.plausibility.level == Plausibility.plausible ? '*' : '';
  return '${c.order.pattern}=${ValueFormatter.format(c.value)}$mark';
}
