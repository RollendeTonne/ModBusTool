import 'package:modbus_explorer/features/interpretation/domain/interpretation_matrix.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';

/// Semicolon CSV opens correctly in German Excel; values use '.' decimals
/// so there is no clash.
const csvSeparator = ';';

/// Tab-separated pastes into every spreadsheet regardless of locale.
const tsvSeparator = '\t';

String matrixToDelimited(
  InterpretationMatrix matrix, {
  String separator = tsvSeparator,
  Scaling scaling = Scaling.identity,
}) {
  final lines = [
    [
      'Type',
      for (final family in InterpretationMatrix.columns)
        family.name.toUpperCase(),
    ],
    for (final row in matrix.rows)
      [
        row.type.technicalName,
        ...row.cells.map((cell) => _cellText(cell, scaling)),
      ],
  ];
  return lines
      .map(
        (fields) => fields.map((f) => quoteField(f, separator)).join(separator),
      )
      .join('\n');
}

String _cellText(MatrixCell? cell, Scaling scaling) =>
    cell == null ? '' : ValueFormatter.format(cell.value, scaling: scaling);

/// RFC 4180 quoting: only when needed.
String quoteField(String field, String separator) {
  final needsQuotes =
      field.contains(separator) ||
      field.contains('"') ||
      field.contains('\n') ||
      field.contains('\r');
  return needsQuotes ? '"${field.replaceAll('"', '""')}"' : field;
}

/// Parses delimited text with RFC 4180 quoting (CRLF or LF line ends).
List<List<String>> parseDelimited(
  String text, {
  String separator = csvSeparator,
}) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == separator) {
      row.add(field.toString());
      field.clear();
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(char);
    }
  }
  row.add(field.toString());
  if (row.any((f) => f.isNotEmpty)) rows.add(row);
  return rows;
}
