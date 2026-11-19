import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/data/register_map_codec.dart';
import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';

const RegisterTable holding = RegisterTable.holdingRegisters;

final samples = [
  RegisterMapEntry(
    id: 'v',
    table: holding,
    address: 52,
    format: NumericFormat(DataType.float32, ByteOrder.parse('ABCD')),
    label: 'Voltage L1',
    unit: 'V',
    description: 'Phase voltage; "RMS"',
  ),
  RegisterMapEntry(
    id: 't',
    table: holding,
    address: 70,
    format: NumericFormat(DataType.int16, ByteOrder.parse('AB')),
    label: 'Temperature',
    unit: '°C',
    scaling: const Scaling(factor: 0.1, decimals: 1),
  ),
  RegisterMapEntry(
    id: 's',
    table: holding,
    address: 30,
    format: TextFormat(
      registerCount: 8,
      swapBytes: true,
      encoding: TextEncoding.utf8,
    ),
    label: 'Serial; number',
  ),
  RegisterMapEntry(
    id: 'b',
    table: holding,
    address: 60,
    format: BitFormat(bit: 3),
    label: 'Alarm',
  ),
  RegisterMapEntry(
    id: 'c',
    table: RegisterTable.coils,
    address: 0,
    format: BitFormat(),
    label: 'Pump',
  ),
];

void main() {
  group('RegisterMapEntry', () {
    test('decodes numeric, text and bit formats', () {
      expect(
        (samples[0].decode([0x4366, 0x199A]) as FloatValue).value,
        closeTo(230.1, 1e-4),
      );
      expect(
        (samples[1].decode([215]) as IntegerValue).value,
        BigInt.from(215),
      );
      expect(
        (samples[2].decode([
          0x424D,
          0x0058,
          0,
          0,
          0,
          0,
          0,
          0,
        ]) as TextValue).text,
        'MBX',
      );
      expect(samples[3].decode([0x0008]), const BoolValue(true));
      expect(samples[3].decode([0xFFF7]), const BoolValue(false));
      expect(samples[4].decode([1]), const BoolValue(true));
    });

    test('too few values is invalid, not an exception', () {
      expect(
        samples[0].decode([0x4366]),
        const InvalidValue(InvalidReason.insufficientData),
      );
    });

    test('covers its register range', () {
      expect(samples[0].covers(holding, 52), isTrue);
      expect(samples[0].covers(holding, 53), isTrue);
      expect(samples[0].covers(holding, 54), isFalse);
      expect(samples[0].covers(RegisterTable.inputRegisters, 52), isFalse);
      expect(samples[2].lastAddress, 37);
    });

    test('rejects formats that do not fit the table', () {
      expect(
        () => RegisterMapEntry(
          id: 'x',
          table: RegisterTable.coils,
          address: 0,
          format: NumericFormat(DataType.uint16, ByteOrder.parse('AB')),
        ),
        throwsArgumentError,
      );
      expect(
        () => RegisterMapEntry(
          id: 'x',
          table: holding,
          address: 0,
          format: BitFormat(),
        ),
        throwsArgumentError,
      );
      expect(
        () => NumericFormat(DataType.float32, ByteOrder.parse('AB')),
        throwsArgumentError,
      );
      expect(
        () => RegisterMapEntry(
          id: 'x',
          table: holding,
          address: 65535,
          format: NumericFormat(DataType.float32, ByteOrder.parse('ABCD')),
        ),
        throwsRangeError,
      );
      expect(() => BitFormat(bit: 16), throwsRangeError);
      expect(() => TextFormat(registerCount: 65), throwsRangeError);
    });
  });

  group('JSON', () {
    test('round-trips every format', () {
      final json = registerMapToJson(samples);
      expect(registerMapFromJson(json), samples);
    });

    test('identity scaling and empty texts are omitted', () {
      final json = entryToJson(samples[4]);
      expect(json.containsKey('scaling'), isFalse);
      expect(json.containsKey('unit'), isFalse);
    });

    test('unreadable entries are skipped and reported', () {
      final json = registerMapToJson(samples);
      (json['entries']! as List).add({
        'id': 'bad',
        'format': {'kind': '?'},
      });
      final skipped = <Object?>[];
      expect(registerMapFromJson(json, skipped: skipped), samples);
      expect(skipped, hasLength(1));
    });
  });

  group('CSV', () {
    var counter = 0;
    String newId() => 'id${counter++}';

    test('round-trips every format (except ids and encoding)', () {
      final csv = registerMapToCsv(samples);
      final result = registerMapFromCsv(csv, newId: newId);
      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(samples.length));
      for (var i = 0; i < samples.length; i++) {
        final expected = samples[i].format is TextFormat
            ? samples[i].copyWith(
                format: TextFormat(registerCount: 8, swapBytes: true),
              )
            : samples[i];
        expect(result.entries[i].copyWith(id: expected.id), expected);
      }
    });

    test('quotes fields containing the separator or quotes', () {
      final csv = registerMapToCsv(samples);
      expect(csv, contains('"Serial; number"'));
      expect(csv, contains('"Phase voltage; ""RMS"""'));
      expect(csv.split('\n').first, csvColumns.join(';'));
    });

    test('accepts decimal commas, any column order and reports bad lines', () {
      const csv =
          'label;table;address;type;order;factor;offset\n'
          'Power;inputRegisters;10;uint32;CDAB;0,01;-5\n'
          'Broken;holdingRegisters;x;uint16;AB;;\n'
          'Wrong type;holdingRegisters;1;float99;AB;;\n';
      final result = registerMapFromCsv(csv, newId: newId);
      expect(result.errors, [3, 4]);
      final entry = result.entries.single;
      expect(entry.label, 'Power');
      expect(entry.table, RegisterTable.inputRegisters);
      expect(entry.scaling.factor, 0.01);
      expect(entry.scaling.offset, -5);
      expect(
        entry.format,
        NumericFormat(DataType.uint32, ByteOrder.parse('CDAB')),
      );
    });

    test('empty input', () {
      expect(registerMapFromCsv('', newId: newId).entries, isEmpty);
    });
  });
}
