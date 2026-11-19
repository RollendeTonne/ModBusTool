import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/rtu_codec.dart';

import '../../../helpers/hex.dart';

void main() {
  group('MBAP', () {
    const framing = MbapFraming();

    test('encodes header with transaction ID and length', () {
      expect(
        framing.encodeFrame(
          unitId: 1,
          pdu: hex('03 00 00 00 0A'),
          transactionId: 0x1234,
        ),
        hex('12 34 00 00 00 06 01 03 00 00 00 0A'),
      );
    });

    test('reassembles a frame split across chunks', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final frame = hex('00 07 00 00 00 05 11 03 02 00 2A');
      expect(assembler.addBytes(frame.sublist(0, 3)), isEmpty);
      expect(assembler.addBytes(frame.sublist(3, 9)), isEmpty);
      final events = assembler.addBytes(frame.sublist(9));
      final decoded = events.single as DecodedFrame;
      expect(decoded.transactionId, 7);
      expect(decoded.unitId, 0x11);
      expect(decoded.pdu, hex('03 02 00 2A'));
      expect(decoded.raw, frame);
      expect(assembler.hasPendingBytes, isFalse);
    });

    test('splits two frames in one chunk', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final events = assembler.addBytes(
        hex('00 01 00 00 00 03 01 83 02  00 02 00 00 00 03 01 83 04'),
      );
      expect(events.map((e) => (e as DecodedFrame).transactionId), [1, 2]);
    });

    test('invalid protocol ID or length is a framing error', () {
      for (final bad in [
        '00 01 00 01 00 03 01 83 02', // protocol id 1
        '00 01 00 00 00 01 01', // length < 2
        '00 01 00 00 01 00 01', // length 256 > 254
      ]) {
        final assembler = framing.newAssembler(expectRequests: false);
        final error = assembler.addBytes(hex(bad)).single as FramingError;
        expect(error.kind, FramingErrorKind.invalidHeader);
        expect(assembler.hasPendingBytes, isFalse);
      }
    });

    test('flush reports incomplete frames', () {
      final assembler = framing.newAssembler(expectRequests: false)
        ..addBytes(hex('00 01 00 00 00 06 01 03'));
      final error = assembler.flush().single as FramingError;
      expect(error.kind, FramingErrorKind.incompleteFrame);
      expect(error.raw, hex('00 01 00 00 00 06 01 03'));
      expect(assembler.flush(), isEmpty);
    });
  });

  group('RTU frame length', () {
    final responses = {
      '01 03 06': 11,
      '01 01 03': 8,
      '01 05': 8,
      '01 06': 8,
      '01 0F': 8,
      '01 10': 8,
      '01 16': 10,
      '01 17 04': 9,
      '01 83': 5,
    };
    for (final MapEntry(key: prefix, value: length) in responses.entries) {
      test('response $prefix… is $length bytes', () {
        expect(rtuFrameLength(hex(prefix), isRequest: false), length);
      });
    }

    final requests = {
      '01 03': 8,
      '01 05': 8,
      '01 0F 00 13 00 0A 02': 11,
      '01 10 00 01 00 02 04': 13,
      '01 16': 10,
      '01 17 00 03 00 06 00 0E 00 03 06': 19,
      '01 2B': 7,
    };
    for (final MapEntry(key: prefix, value: length) in requests.entries) {
      test('request $prefix… is $length bytes', () {
        expect(rtuFrameLength(hex(prefix), isRequest: true), length);
      });
    }

    test('needs more bytes before byte count is known', () {
      expect(rtuFrameLength(hex('01'), isRequest: false), isNull);
      expect(rtuFrameLength(hex('01 03'), isRequest: false), isNull);
      expect(rtuFrameLength(hex('01 10 00 01 00 02'), isRequest: true), isNull);
    });

    test('device ID response length follows the object list', () {
      // unit fc mei code conf more next n | 00 03 'ABC' | 01 01 'P' | crc
      final body = hex('01 2B 0E 01 81 00 00 02 00 03 41 42 43 01 01 50');
      expect(rtuFrameLength(body.sublist(0, 8), isRequest: false), isNull);
      expect(rtuFrameLength(body.sublist(0, 10), isRequest: false), isNull);
      expect(rtuFrameLength(body, isRequest: false), body.length + 2);
    });

    test('unknown function codes', () {
      expect(rtuFrameLength(hex('01 07'), isRequest: false), unknownRtuLength);
      expect(rtuFrameLength(hex('01 83'), isRequest: true), unknownRtuLength);
    });
  });

  group('RTU assembler', () {
    const framing = RtuFraming();

    test('encode appends CRC', () {
      expect(
        framing.encodeFrame(unitId: 0x11, pdu: hex('03 00 6B 00 03')),
        hex('11 03 00 6B 00 03 76 87'),
      );
    });

    test('decodes a byte-by-byte response', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final frame = framing.encodeFrame(
        unitId: 1,
        pdu: hex('03 04 00 01 00 02'),
      );
      final events = <FramingEvent>[];
      for (final b in frame) {
        events.addAll(assembler.addBytes([b]));
      }
      final decoded = events.single as DecodedFrame;
      expect(decoded.unitId, 1);
      expect(decoded.pdu, hex('03 04 00 01 00 02'));
      expect(decoded.transactionId, isNull);
    });

    test('decodes exception and request frames', () {
      final responses = framing.newAssembler(expectRequests: false);
      final exception = framing.encodeFrame(unitId: 5, pdu: hex('83 02'));
      expect(
        (responses.addBytes(exception).single as DecodedFrame).pdu,
        hex('83 02'),
      );

      final requests = framing.newAssembler(expectRequests: true);
      final write = framing.encodeFrame(
        unitId: 5,
        pdu: hex('10 00 01 00 02 04 00 0A 01 02'),
      );
      expect((requests.addBytes(write).single as DecodedFrame).unitId, 5);
    });

    test('CRC mismatch is reported with the raw frame', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final frame = framing.encodeFrame(unitId: 1, pdu: hex('06 00 01 00 03'));
      frame[3] ^= 0xFF;
      final error = assembler.addBytes(frame).single as FramingError;
      expect(error.kind, FramingErrorKind.crcMismatch);
      expect(error.raw, frame);
    });

    test('back-to-back frames', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final a = framing.encodeFrame(unitId: 1, pdu: hex('06 00 01 00 03'));
      final b = framing.encodeFrame(unitId: 2, pdu: hex('83 01'));
      final events = assembler.addBytes([...a, ...b]);
      expect(events.map((e) => (e as DecodedFrame).unitId), [1, 2]);
    });

    test('unknown function code drops the buffer', () {
      final assembler = framing.newAssembler(expectRequests: false);
      final error =
          assembler.addBytes(hex('01 07 00 00')).single as FramingError;
      expect(error.kind, FramingErrorKind.unknownFunctionCode);
      expect(assembler.hasPendingBytes, isFalse);
    });

    test('flush reports partial frame', () {
      final assembler = framing.newAssembler(expectRequests: false)
        ..addBytes(hex('01 03 04 00'));
      expect(
        (assembler.flush().single as FramingError).kind,
        FramingErrorKind.incompleteFrame,
      );
    });
  });

  group('RTU inter-frame delay', () {
    test('t3.5 at 9600 baud ≈ 4.01 ms', () {
      expect(rtuInterFrameDelay(9600).inMicroseconds, 4011);
    });

    test('t3.5 at 19200 baud ≈ 2.01 ms', () {
      expect(rtuInterFrameDelay(19200).inMicroseconds, 2006);
    });

    test('fixed 1.75 ms above 19200 baud', () {
      expect(rtuInterFrameDelay(115200), const Duration(microseconds: 1750));
    });
  });
}
