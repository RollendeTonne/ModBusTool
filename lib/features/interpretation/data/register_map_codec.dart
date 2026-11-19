import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/matrix_export.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/domain/text_decoder.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

const registerMapSchemaVersion = 1;

Map<String, Object?> entryToJson(RegisterMapEntry e) => {
  'id': e.id,
  'table': e.table.name,
  'address': e.address,
  if (e.label.isNotEmpty) 'label': e.label,
  if (e.unit.isNotEmpty) 'unit': e.unit,
  if (e.description.isNotEmpty) 'description': e.description,
  'format': switch (e.format) {
    NumericFormat(:final type, :final order) => {
      'kind': 'numeric',
      'type': type.name,
      'order': order.pattern,
    },
    TextFormat(:final registerCount, :final swapBytes, :final encoding) => {
      'kind': 'text',
      'registers': registerCount,
      'swapBytes': swapBytes,
      'encoding': encoding.name,
    },
    BitFormat(:final bit) => {'kind': 'bit', 'bit': ?bit},
  },
  if (!e.scaling.isIdentity)
    'scaling': {
      'factor': e.scaling.factor,
      'offset': e.scaling.offset,
      'decimals': ?e.scaling.decimals,
    },
};

RegisterMapEntry entryFromJson(Map<String, Object?> json) {
  final format = json['format']! as Map<String, Object?>;
  final scaling = json['scaling'] as Map<String, Object?>?;
  return RegisterMapEntry(
    id: json['id']! as String,
    table: RegisterTable.values.byName(json['table']! as String),
    address: json['address']! as int,
    label: json['label'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    description: json['description'] as String? ?? '',
    format: switch (format['kind']) {
      'numeric' => NumericFormat(
        DataType.values.byName(format['type']! as String),
        ByteOrder.parse(format['order']! as String),
      ),
      'text' => TextFormat(
        registerCount: format['registers']! as int,
        swapBytes: format['swapBytes'] as bool? ?? false,
        encoding: TextEncoding.values.byName(
          format['encoding'] as String? ?? 'ascii',
        ),
      ),
      'bit' => BitFormat(bit: format['bit'] as int?),
      final kind => throw FormatException('Unknown format kind $kind'),
    },
    scaling: scaling == null
        ? Scaling.identity
        : Scaling(
            factor: (scaling['factor'] as num? ?? 1).toDouble(),
            offset: (scaling['offset'] as num? ?? 0).toDouble(),
            decimals: scaling['decimals'] as int?,
          ),
  );
}

/// Skips unreadable entries; returns them in [skipped] for reporting.
List<RegisterMapEntry> entriesFromJsonList(
  Object? list, {
  List<Object?>? skipped,
}) {
  if (list is! List) return const [];
  final result = <RegisterMapEntry>[];
  for (final item in list) {
    try {
      result.add(entryFromJson(item! as Map<String, Object?>));
    } on Object {
      skipped?.add(item);
    }
  }
  return result;
}

/// Stand-alone export document (one map), for files shared between users.
Map<String, Object?> registerMapToJson(List<RegisterMapEntry> entries) => {
  'version': registerMapSchemaVersion,
  'entries': [for (final e in entries) entryToJson(e)],
};

List<RegisterMapEntry> registerMapFromJson(
  Object? json, {
  List<Object?>? skipped,
}) => json is Map
    ? entriesFromJsonList(json['entries'], skipped: skipped)
    : const [];

// ------------------------------------------------------------------ CSV

/// Column order of the CSV format. Addresses are 0-based protocol
/// addresses so files are independent of the display setting.
const csvColumns = [
  'table',
  'address',
  'label',
  'unit',
  'type',
  'order',
  'registers',
  'bit',
  'factor',
  'offset',
  'decimals',
  'description',
];

String registerMapToCsv(List<RegisterMapEntry> entries) {
  final lines = [csvColumns.join(csvSeparator)];
  for (final e in entries) {
    final (type, order, registers, bit) = switch (e.format) {
      NumericFormat(:final type, :final order) => (
        type.name,
        order.pattern,
        '',
        '',
      ),
      TextFormat(:final registerCount, :final swapBytes) => (
        'text',
        swapBytes ? 'BA' : 'AB',
        '$registerCount',
        '',
      ),
      BitFormat(:final bit) => ('bit', '', '', bit?.toString() ?? ''),
    };
    final fields = [
      e.table.name,
      '${e.address}',
      e.label,
      e.unit,
      type,
      order,
      registers,
      bit,
      if (e.scaling.isIdentity) '' else _number(e.scaling.factor),
      if (e.scaling.isIdentity) '' else _number(e.scaling.offset),
      e.scaling.decimals?.toString() ?? '',
      e.description,
    ];
    lines.add(
      fields.map((f) => quoteField(f, csvSeparator)).join(csvSeparator),
    );
  }
  return lines.join('\n');
}

String _number(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Result of a CSV import: parsed entries plus 1-based line numbers that
/// could not be read.
typedef CsvImportResult = ({List<RegisterMapEntry> entries, List<int> errors});

CsvImportResult registerMapFromCsv(
  String text, {
  required String Function() newId,
}) {
  final rows = parseDelimited(text);
  if (rows.isEmpty) return (entries: const [], errors: const []);
  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  int col(String name) => header.indexOf(name);
  final entries = <RegisterMapEntry>[];
  final errors = <int>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    String field(String name) {
      final index = col(name);
      return index >= 0 && index < row.length ? row[index].trim() : '';
    }

    try {
      final table = RegisterTable.values.byName(field('table'));
      final type = field('type').toLowerCase();
      final format = switch (type) {
        'text' => TextFormat(
          registerCount: int.parse(field('registers')),
          swapBytes: field('order').toUpperCase() == 'BA',
        ),
        'bit' => BitFormat(
          bit: field('bit').isEmpty ? null : int.parse(field('bit')),
        ),
        _ => NumericFormat(
          DataType.values.byName(type),
          ByteOrder.parse(field('order')),
        ),
      };
      final factor = field('factor');
      final offset = field('offset');
      final decimals = field('decimals');
      entries.add(
        RegisterMapEntry(
          id: newId(),
          table: table,
          address: int.parse(field('address')),
          format: format,
          label: field('label'),
          unit: field('unit'),
          description: field('description'),
          scaling: Scaling(
            factor: factor.isEmpty
                ? 1
                : double.parse(factor.replaceAll(',', '.')),
            offset: offset.isEmpty
                ? 0
                : double.parse(offset.replaceAll(',', '.')),
            decimals: decimals.isEmpty ? null : int.parse(decimals),
          ),
        ),
      );
    } on Object {
      errors.add(i + 1);
    }
  }
  return (entries: entries, errors: errors);
}
