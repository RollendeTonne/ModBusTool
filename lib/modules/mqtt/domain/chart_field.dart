import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';

/// Where the numeric value of a message comes from.
@immutable
sealed class ChartField {
  const new();

  /// `null` if the message has no usable number there.
  double? extract(MqttMessageRecord record);

  String get label;
}

/// The whole payload is a number (`21.5`).
final class TextNumberField extends ChartField {
  const new();

  @override
  double? extract(MqttMessageRecord record) {
    final text = analyzeCached(record.payload).text?.trim();
    return text == null ? null : double.tryParse(text);
  }

  @override
  String get label => 'payload';

  @override
  bool operator ==(Object other) => other is TextNumberField;

  @override
  int get hashCode => 0;
}

/// A JSON value; numbers, numeric strings and booleans (1/0) count.
final class JsonPathField extends ChartField {
  const new(this.path);

  final List<Object> path;

  @override
  double? extract(MqttMessageRecord record) {
    final analysis = analyzeCached(
      record.payload,
      contentType: record.properties.contentType,
    );
    if (!analysis.isJsonValid) return null;
    final (found, value) = valueAt(analysis.json, path);
    if (!found) return null;
    return switch (value) {
      num() => value.toDouble(),
      bool() => value ? 1 : 0,
      String() => double.tryParse(value.trim()),
      _ => null,
    };
  }

  @override
  String get label => jsonPath(path);

  @override
  bool operator ==(Object other) =>
      other is JsonPathField && jsonPath(other.path) == jsonPath(path);

  @override
  int get hashCode => jsonPath(path).hashCode;
}

/// A binary value decoded with the shared engine.
final class BinaryField extends ChartField {
  const new({required this.offset, required this.type, required this.order});

  final int offset;
  final DataType type;
  final ByteOrderFamily order;

  @override
  double? extract(MqttMessageRecord record) {
    if (type.byteWidth < 2) return null;
    final value = decodeValue(
      record.payload,
      type,
      ByteOrder.of(order, type.byteWidth),
      offset: offset,
    ).numericValue;
    return value == null || value.isNaN || value.isInfinite ? null : value;
  }

  @override
  String get label =>
      '${type.technicalName} ${order.name.toUpperCase()} @ $offset';

  @override
  bool operator ==(Object other) =>
      other is BinaryField &&
      other.offset == offset &&
      other.type == type &&
      other.order == order;

  @override
  int get hashCode => Object.hash(offset, type, order);
}

@immutable
final class ChartPoint {
  const new(this.time, this.value);

  final DateTime time;
  final double value;
}

/// Points of [field] over [history]; messages without a value are skipped.
List<ChartPoint> chartSeries(
  Iterable<MqttMessageRecord> history,
  ChartField field,
) => [
  for (final r in history)
    if (field.extract(r) case final value?) ChartPoint(r.timestamp, value),
];

/// Sensible default: numeric text payloads chart themselves.
ChartField? defaultChartField(MqttMessageRecord? last) {
  if (last == null) return null;
  const text = TextNumberField();
  return text.extract(last) != null ? text : null;
}
