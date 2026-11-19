import 'package:modbus_explorer/features/interpretation/domain/float_utils.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/features/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/features/interpretation/domain/text_decoder.dart';

/// Language-neutral text rendering of interpreted values (also used for
/// CSV export, hence plain ASCII for special values).
abstract final class ValueFormatter {
  static const invalidPlaceholder = '—';
  static const nonPrintableReplacement = '·';

  static String format(
    InterpretedValue value, {
    Scaling scaling = Scaling.identity,
  }) {
    final numeric = value.numericValue;
    if (!scaling.isIdentity && numeric != null && numeric.isFinite) {
      return formatScaled(scaling.apply(numeric), scaling.decimals);
    }
    return switch (value) {
      IntegerValue(:final value) => value.toString(),
      FloatValue(:final value, :final precision) => formatFloat(
        value,
        precision,
      ),
      TimestampValue(:final value) => formatTimestamp(value),
      TextValue(:final text) => String.fromCharCodes(
        text.runes.map(
          (r) =>
              isControlCharacter(r) ? nonPrintableReplacement.codeUnitAt(0) : r,
        ),
      ),
      InvalidValue() => invalidPlaceholder,
    };
  }

  /// Shortest decimal that round-trips at the value's own precision, so a
  /// float32 230.1 shows as `230.1`, not `230.10000610351562`.
  static String formatFloat(double value, FloatPrecision precision) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-Inf' : 'Inf';
    if (precision == FloatPrecision.double) return value.toString();
    for (var digits = 1; digits <= 9; digits++) {
      final candidate = double.parse(value.toStringAsPrecision(digits));
      if (toFloat32(candidate) == value) return candidate.toString();
    }
    return value.toString();
  }

  static String formatScaled(double value, int? decimals) {
    if (decimals != null) return value.toStringAsFixed(decimals);
    // 15 significant digits hide binary noise like 123.40000000000001.
    return double.parse(value.toStringAsPrecision(15)).toString();
  }

  static String formatTimestamp(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final date =
        '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
        '${two(utc.day)}';
    final time = '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}';
    final millis = utc.millisecond == 0
        ? ''
        : '.${utc.millisecond.toString().padLeft(3, '0')}';
    return '$date $time${millis}Z';
  }
}

String formatHex(int value, {int digits = 4, bool prefix = true}) =>
    '${prefix ? '0x' : ''}'
    '${value.toRadixString(16).toUpperCase().padLeft(digits, '0')}';

String formatHexBytes(List<int> bytes, {String separator = ' '}) => bytes
    .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
    .join(separator);

/// Binary with a space every 4 bits for readability.
String formatBinary(int value, {int bits = 16}) {
  final raw = value.toRadixString(2).padLeft(bits, '0');
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}
