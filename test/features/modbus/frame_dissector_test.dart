import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/modbus/data/codec/frame_dissector.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/rtu_codec.dart';

import '../../helpers/hex.dart';

List<SegmentKind> kinds(FrameDissection d) =>
    d.segments.map((s) => s.kind).toList();

void main() {
  group('TCP', () {
    test('read request', () {
      final d = dissectFrame(
        hex('00 01 00 00 00 06 11 03 00 6B 00 03'),
        FrameKind.tcp,
        isRequest: true,
      );
      expect(kinds(d), [
        SegmentKind.transactionId,
        SegmentKind.protocolId,
        SegmentKind.length,
        SegmentKind.unitId,
        SegmentKind.functionCode,
        SegmentKind.address,
        SegmentKind.count,
      ]);
      expect(d.functionCode, 3);
      expect(d.crcValid, isNull);
      expect(d.isComplete, isTrue);
      final address = d.segments[5];
      expect(address.offset, 8);
      expect(address.length, 2);
      expect(address.display, '0x006B (107)');
      expect(d.segments[4].display, contains('readHoldingRegisters'));
    });

    test('register response lists values', () {
      final d = dissectFrame(
        hex('00 01 00 00 00 09 11 03 06 02 2B 00 00 00 64'),
        FrameKind.tcp,
        isRequest: false,
      );
      final values = d.segments.last;
      expect(values.kind, SegmentKind.valueList);
      expect(values.display, '0x022B 0x0000 0x0064');
    });

    test('exception response names the code', () {
      final d = dissectFrame(
        hex('00 01 00 00 00 03 01 83 02'),
        FrameKind.tcp,
        isRequest: false,
      );
      expect(d.isException, isTrue);
      expect(d.segments.last.kind, SegmentKind.exceptionCode);
      expect(d.segments.last.display, contains('ILLEGAL DATA ADDRESS'));
    });

    test('wrong length field and protocol ID are flagged', () {
      final d = dissectFrame(
        hex('00 01 00 01 00 09 01 06 00 01 00 03'),
        FrameKind.tcp,
        isRequest: true,
      );
      expect(d.segments[1].isValid, isFalse); // protocol id
      expect(d.segments[2].isValid, isFalse); // length 9 vs 6
    });

    test('truncated frame', () {
      final d = dissectFrame(
        hex('00 01 00 00 00 06 01 03 00'),
        FrameKind.tcp,
        isRequest: true,
      );
      expect(d.isComplete, isFalse);
      expect(d.segments.last.kind, SegmentKind.truncated);
    });
  });

  group('RTU', () {
    const framing = RtuFraming();

    test('valid CRC', () {
      final d = dissectFrame(
        hex('11 03 00 6B 00 03 76 87'),
        FrameKind.rtu,
        isRequest: true,
      );
      expect(kinds(d), [
        SegmentKind.unitId,
        SegmentKind.functionCode,
        SegmentKind.address,
        SegmentKind.count,
        SegmentKind.crc,
      ]);
      expect(d.crcValid, isTrue);
      expect(d.segments.last.display, '0x8776');
    });

    test('invalid CRC shows expected value', () {
      final d = dissectFrame(
        hex('11 03 00 6B 00 03 00 00'),
        FrameKind.rtu,
        isRequest: true,
      );
      expect(d.crcValid, isFalse);
      expect(d.segments.last.isValid, isFalse);
      expect(d.segments.last.display, '0x0000 ≠ 0x8776');
    });

    test('write multiple coils request shows bits in address order', () {
      final frame = framing.encodeFrame(
        unitId: 1,
        pdu: hex('0F 00 13 00 0A 02 CD 01'),
      );
      final d = dissectFrame(frame, FrameKind.rtu, isRequest: true);
      final values = d.segments.firstWhere(
        (s) => s.kind == SegmentKind.valueList,
      );
      expect(values.display, '10110011 10000000');
    });

    test('device identification response objects', () {
      final frame = framing.encodeFrame(
        unitId: 1,
        pdu: hex('2B 0E 01 81 00 00 02 00 03 41 42 43 01 01 50'),
      );
      final d = dissectFrame(frame, FrameKind.rtu, isRequest: false);
      final objects = d.segments
          .where((s) => s.kind == SegmentKind.object)
          .map((s) => s.display);
      expect(objects, ['0x00: ABC', '0x01: P']);
      expect(d.isComplete, isTrue);
    });

    test('extra bytes are trailing', () {
      final d = dissectFrame(
        framing.encodeFrame(unitId: 1, pdu: hex('06 00 01 00 03 FF')),
        FrameKind.rtu,
        isRequest: true,
      );
      expect(kinds(d), contains(SegmentKind.trailing));
    });

    test('never throws on garbage', () {
      for (final bytes in [
        '',
        '01',
        '01 03',
        'FF FF FF',
        '01 2B 0E 01 81 00 00 05',
      ]) {
        expect(
          () => dissectFrame(hex(bytes), FrameKind.rtu, isRequest: false),
          returnsNormally,
        );
        expect(
          () => dissectFrame(hex(bytes), FrameKind.tcp, isRequest: false),
          returnsNormally,
        );
      }
    });
  });
}
