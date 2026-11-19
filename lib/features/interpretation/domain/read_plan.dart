import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

@immutable
final class ReadRange {
  const new(this.table, this.start, this.count);

  final RegisterTable table;
  final int start;
  final int count;

  int get end => start + count - 1;

  @override
  bool operator ==(Object other) =>
      other is ReadRange &&
      other.table == table &&
      other.start == start &&
      other.count == count;

  @override
  int get hashCode => Object.hash(table, start, count);

  @override
  String toString() => 'ReadRange(${table.name} $start+$count)';
}

/// Merges ranges into as few requests as the protocol allows.
///
/// Neighbouring ranges are combined when the gap between them is at most
/// [maxGap] items; reading a few unused registers is cheaper than an extra
/// round trip. Devices that reject reads of gaps (exception 02) can be
/// handled with `maxGap: 0`.
List<ReadRange> planReads(Iterable<ReadRange> ranges, {int maxGap = 8}) {
  final result = <ReadRange>[];
  for (final table in RegisterTable.values) {
    final sorted = ranges.where((r) => r.table == table).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (sorted.isEmpty) continue;
    final limit = table.isBitTable
        ? ModbusLimits.maxReadBits
        : ModbusLimits.maxReadRegisters;
    var start = sorted.first.start;
    var end = sorted.first.end;
    for (final range in sorted.skip(1)) {
      final mergedEnd = range.end > end ? range.end : end;
      final fits = mergedEnd - start + 1 <= limit;
      if (range.start <= end + 1 + maxGap && fits) {
        end = mergedEnd;
      } else {
        result.add(ReadRange(table, start, end - start + 1));
        start = range.start;
        end = range.end;
      }
    }
    result.add(ReadRange(table, start, end - start + 1));
  }
  return result;
}
