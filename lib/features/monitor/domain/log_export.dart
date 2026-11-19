import 'package:modbus_explorer/features/interpretation/domain/matrix_export.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/data/codec/frame_dissector.dart';
import 'package:modbus_explorer/features/modbus/domain/function_code.dart';

/// `HH:mm:ss.mmm`, local time – log lines are read by people on site.
String formatLogTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
      '${t.millisecond.toString().padLeft(3, '0')}';
}

/// Function code of a frame (`FC03`, `FC83` for exceptions) or `—`.
String frameFunctionLabel(FrameEvent frame) {
  final fc = dissectFrame(
    frame.bytes,
    frame.kind,
    isRequest: frame.isRequest,
  ).functionCode;
  if (fc == null) return ValueFormatter.invalidPlaceholder;
  return 'FC${fc.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}

/// Function code without the exception flag, for filtering.
int? frameBaseFunctionCode(FrameEvent frame) {
  final fc = dissectFrame(
    frame.bytes,
    frame.kind,
    isRequest: frame.isRequest,
  ).functionCode;
  return fc == null ? null : fc & ~FunctionCode.exceptionFlag;
}

bool frameIsError(FrameEvent frame) =>
    frame.status != FrameStatus.ok ||
    dissectFrame(
      frame.bytes,
      frame.kind,
      isRequest: frame.isRequest,
    ).isException;

String frameToLine(FrameEvent f, {Duration? latency}) => [
  formatLogTime(f.timestamp),
  f.direction.name.toUpperCase(),
  f.kind.name.toUpperCase(),
  if (f.transactionNumber != null) '#${f.transactionNumber}' else '#-',
  frameFunctionLabel(f),
  '[${f.bytes.length}]',
  formatHexBytes(f.bytes),
  f.status.name.toUpperCase(),
  if (latency != null) '${latency.inMilliseconds} ms',
].join('  ');

const logCsvColumns = [
  'timestamp',
  'direction',
  'framing',
  'transaction',
  'function',
  'length',
  'status',
  'latency_ms',
  'bytes',
];

String framesToCsv(
  Iterable<FrameEvent> frames, {
  Duration? Function(FrameEvent frame)? latencyOf,
}) {
  final lines = [logCsvColumns.join(csvSeparator)];
  for (final f in frames) {
    final latency = latencyOf?.call(f);
    lines.add(
      [
        f.timestamp.toIso8601String(),
        f.direction.name,
        f.kind.name,
        f.transactionNumber?.toString() ?? '',
        frameFunctionLabel(f),
        '${f.bytes.length}',
        f.status.name,
        latency?.inMilliseconds.toString() ?? '',
        formatHexBytes(f.bytes),
      ].map((v) => quoteField(v, csvSeparator)).join(csvSeparator),
    );
  }
  return lines.join('\n');
}
