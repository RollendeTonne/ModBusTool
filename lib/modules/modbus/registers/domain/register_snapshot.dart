import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';

/// Result of one read, with per-item "changed since previous read" times.
@immutable
final class RegisterSnapshot {
  const new({
    required this.table,
    required this.start,
    required this.values,
    required this.readAt,
    required this.changedAt,
    this.latency,
  });

  factory initial({
    required RegisterTable table,
    required int start,
    required List<int> values,
    required DateTime readAt,
    Duration? latency,
  }) => RegisterSnapshot(
    table: table,
    start: start,
    values: List.unmodifiable(values),
    readAt: readAt,
    changedAt: List.filled(values.length, null),
    latency: latency,
  );

  final RegisterTable table;
  final int start;

  /// Register values, or 0/1 for coils and discrete inputs.
  final List<int> values;
  final DateTime readAt;
  final List<DateTime?> changedAt;
  final Duration? latency;

  int get count => values.length;
  int get end => start + count - 1;

  bool covers(RegisterTable t, int address) =>
      t == table && address >= start && address <= end;

  int? valueAt(int address) =>
      address >= start && address <= end ? values[address - start] : null;

  /// Follow-up read: marks items whose value differs from this snapshot.
  /// A different range starts fresh (nothing is marked as changed).
  RegisterSnapshot next(
    List<int> newValues,
    DateTime now, {
    required RegisterTable table,
    required int start,
    Duration? latency,
  }) {
    if (table != this.table ||
        start != this.start ||
        newValues.length != count) {
      return RegisterSnapshot.initial(
        table: table,
        start: start,
        values: newValues,
        readAt: now,
        latency: latency,
      );
    }
    return RegisterSnapshot(
      table: table,
      start: start,
      values: List.unmodifiable(newValues),
      readAt: now,
      changedAt: List.unmodifiable(
        List.generate(
          count,
          (i) => newValues[i] != values[i] ? now : changedAt[i],
        ),
      ),
      latency: latency,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RegisterSnapshot &&
      other.table == table &&
      other.start == start &&
      other.readAt == readAt &&
      const ListEquality<int>().equals(other.values, values);

  @override
  int get hashCode => Object.hash(table, start, readAt, values.length);
}
