import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));
Uint8List raw(List<int> bytes) => Uint8List.fromList(bytes);

void main() {
  group('auto-detection', () {
    final cases = <(String, Uint8List, PayloadKind)>[
      ('empty', Uint8List(0), PayloadKind.empty),
      ('object', b('{"a": 1}'), PayloadKind.json),
      ('array with whitespace', b('  [1, 2]\n'), PayloadKind.json),
      ('number is text', b('21.5'), PayloadKind.text),
      ('quoted string is text', b('"on"'), PayloadKind.text),
      ('word', b('running'), PayloadKind.text),
      ('sentence', b('Hello MQTT world'), PayloadKind.text),
      ('umlauts', b('Grüße'), PayloadKind.text),
      ('xml', b('<?xml version="1.0"?><a><b>1</b></a>'), PayloadKind.xml),
      ('xml element', b('<sensor id="1">5</sensor>'), PayloadKind.xml),
      ('base64 padded', b('SGVsbG8gV29ybGQ='), PayloadKind.base64),
      ('base64 mixed', b('AAECAwQFBgcICQoL'), PayloadKind.text),
      ('base64 mixed case', b('QmluYXJ5RGF0YTEy'), PayloadKind.base64),
      ('hex string stays text', b('DEADBEEF'), PayloadKind.text),
      ('digits stay text', b('12345678'), PayloadKind.text),
      ('invalid utf-8', raw([0xC3, 0x28]), PayloadKind.binary),
      ('control bytes', raw([0x00, 0x01, 0x02, 0x03]), PayloadKind.binary),
      ('float32', raw([0x41, 0x48, 0x00, 0x00]), PayloadKind.binary),
    ];
    for (final (name, payload, kind) in cases) {
      test(name, () => expect(analyzePayload(payload).kind, kind));
    }

    test('content type JSON makes primitives JSON', () {
      final a = analyzePayload(b('42'), contentType: 'application/json');
      expect(a.kind, PayloadKind.json);
      expect(a.json, 42);
    });

    test('broken JSON is located', () {
      final a = analyzePayload(b('{\n  "a": 1,\n  "b": x\n}'));
      expect(a.kind, PayloadKind.json);
      expect(a.isJsonValid, isFalse);
      final issue = a.syntaxIssue!;
      expect(issue.line, 3);
      expect(issue.column, 8);
      expect(issue.lineOf(a.text!), '  "b": x');
    });

    test('base64 payload is decoded', () {
      final a = analyzePayload(b('SGVsbG8gV29ybGQ='));
      expect(utf8.decode(a.base64Decoded!), 'Hello World');
    });

    test('analysis is cached per payload instance', () {
      final payload = b('{"x": true}');
      expect(identical(analyzeCached(payload), analyzeCached(payload)), isTrue);
    });
  });

  group('XML', () {
    test('well-formed documents pass', () {
      for (final xml in [
        '<a/>',
        '<a><b x="1"/><c>text</c></a>',
        '<?xml version="1.0"?><!-- c --><a><![CDATA[<x>]]></a>',
      ]) {
        expect(checkXml(xml), isNull, reason: xml);
      }
    });

    test('errors name the problem and location', () {
      expect(checkXml('<a><b></a>')!.message, 'Expected </b>, found </a>');
      expect(checkXml('<a>')!.message, contains('not closed'));
      expect(checkXml('<a/><b/>')!.message, contains('root'));
      expect(checkXml('<a>\n</b>')!.line, 2);
    });

    test('pretty print indents by depth', () {
      expect(
        prettyXml('<a><b>1</b><c/></a>'),
        '<a>\n  <b>\n    1\n  </b>\n  <c/>\n</a>',
      );
      expect(prettyXml('<a><b></a>'), '<a><b></a>'); // broken: unchanged
    });
  });

  group('JSON path', () {
    test('notation for keys, indices and special keys', () {
      expect(jsonPath(const []), r'$');
      expect(jsonPath(const ['sensor', 'temp']), r'$.sensor.temp');
      expect(jsonPath(const ['list', 2, 'v']), r'$.list[2].v');
      expect(jsonPath(const ['a b', "it's"]), r"$['a b']['it\'s']");
      expect(jsonPath(const ['1st']), r"$['1st']");
    });

    test('parse is the inverse of format', () {
      for (final segments in [
        const <Object>['sensor', 'temp'],
        const <Object>['list', 0, 'x y', 3],
        const <Object>["q'uote", r'back\slash'],
      ]) {
        expect(parseJsonPath(jsonPath(segments)), segments);
      }
      expect(parseJsonPath('sensor.temp'), isNull);
      expect(parseJsonPath(r'$.a[x]'), isNull);
    });

    test('valueAt distinguishes missing from null', () {
      final json = jsonDecode('{"a": {"b": [10, null]}}');
      expect(valueAt(json, const ['a', 'b', 0]), (true, 10));
      expect(valueAt(json, const ['a', 'b', 1]), (true, null));
      expect(valueAt(json, const ['a', 'b', 5]).$1, isFalse);
      expect(valueAt(json, const ['a', 'x']).$1, isFalse);
      expect(valueAt(json, const ['a', 0]).$1, isFalse);
    });
  });

  group('text encodings', () {
    final bytes = raw([0x47, 0xFC, 0x6E]); // "Gün" in Latin-1
    test('UTF-8 marks invalid bytes, Latin-1 decodes, ASCII replaces', () {
      expect(decodeText(bytes, TextEncoding.utf8), 'G�n');
      expect(decodeText(bytes, TextEncoding.latin1), 'Gün');
      expect(decodeText(bytes, TextEncoding.ascii), 'G�n');
      expect(decodeText(b('Gün'), TextEncoding.utf8), 'Gün');
    });
  });

  group('hex dump', () {
    test('offsets, padding and ASCII column', () {
      final lines = hexDump(b('Hello, MQTT world! 0123'));
      expect(lines, hasLength(2));
      expect(lines[0].offsetLabel, '00000000');
      expect(lines[0].hex, '48 65 6C 6C 6F 2C 20 4D  51 54 54 20 77 6F 72 6C');
      expect(lines[0].ascii, 'Hello, MQTT worl');
      expect(lines[1].offsetLabel, '00000010');
      expect(lines[1].hex, startsWith('64 21 20 30 31 32 33   '));
      expect(lines[1].hex.length, lines[0].hex.length);
      expect(hexDump(raw([0, 0x7F, 0x41])).single.ascii, '..A');
      expect(hexDump(Uint8List(100), maxLines: 2), hasLength(2));
    });
  });

  group('binary interpretation (shared engine on bytes)', () {
    // 12.5 as FLOAT32 big endian: 41 48 00 00.
    final payload = raw([0xFF, 0x41, 0x48, 0x00, 0x00, 0x01]);

    String cell(InterpretationMatrix m, DataType type, ByteOrderFamily f) =>
        ValueFormatter.format(
          m.rows.firstWhere((r) => r.type == type).cells[f.index]!.value,
        );

    test('offset window and all byte orders', () {
      final m = InterpretationMatrix.fromBytes(byteWindow(payload, 1));
      expect(m.registers, isEmpty);
      expect(cell(m, DataType.float32, ByteOrderFamily.abcd), '12.5');
      expect(cell(m, DataType.uint16, ByteOrderFamily.abcd), '16712');
      expect(cell(m, DataType.uint16, ByteOrderFamily.badc), '18497');
      // DCBA reads 00 00 48 41.
      expect(cell(m, DataType.uint32, ByteOrderFamily.dcba), '18497');
      // 5 bytes: 64-bit types have no value.
      final row64 = m.rows.firstWhere((r) => r.type == DataType.int64);
      expect(row64.cells.every((c) => c == null), isTrue);
    });

    test('same result as the register path for even lengths', () {
      final fromBytes = InterpretationMatrix.fromBytes(raw([0x41, 0x48, 0, 0]));
      final fromRegisters = InterpretationMatrix.compute(const [0x4148, 0]);
      for (var r = 0; r < fromBytes.rows.length; r++) {
        for (var c = 0; c < 4; c++) {
          expect(
            fromBytes.rows[r].cells[c]?.orderedBytes,
            fromRegisters.rows[r].cells[c]?.orderedBytes,
          );
        }
      }
    });

    test('8-bit values and bits', () {
      expect(byteValues(payload, 0), (-1, 255));
      expect(byteValues(payload, 1), (65, 65));
      expect(byteValues(payload, 6), isNull);
      expect(bitsOf(payload, 1, 2), [
        [0, 1, 0, 0, 0, 0, 0, 1],
        [0, 1, 0, 0, 1, 0, 0, 0],
      ]);
      expect(bitsOf(payload, 5, 4), hasLength(1));
      expect(byteWindow(payload, 4, 10), [0x00, 0x01]);
      expect(byteWindow(payload, 99), isEmpty);
    });
  });
}
