import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/features/interpretation/presentation/register_map_controller.dart';

@immutable
final class TrendPoint {
  const new(this.time, this.value);

  final DateTime time;
  final double value;
}

@immutable
final class TrendState {
  const new({this.selected = const [], this.series = const {}});

  /// Entry IDs to plot, in selection order.
  final List<String> selected;

  /// Entry ID → points, oldest first.
  final Map<String, List<TrendPoint>> series;
}

/// Collects values of numeric register map entries whenever the map is
/// read (or polled).
final class TrendController extends Notifier<TrendState> {
  static const maxSeries = 4;
  static const maxPoints = 600;

  @override
  TrendState build() {
    ref.listen(mapValuesControllerProvider, (previous, next) {
      final readAt = next.readAt;
      if (readAt == null || readAt == previous?.readAt) return;
      _record(next, readAt);
    });
    return const TrendState();
  }

  void _record(MapValuesState values, DateTime at) {
    final entries = {
      for (final e in ref.read(currentMapEntriesProvider)) e.id: e,
    };
    final series = <String, List<TrendPoint>>{...state.series};
    for (final MapEntry(key: id, value: mapValue) in values.values.entries) {
      final entry = entries[id];
      final raw = mapValue.value.numericValue;
      if (entry == null || entry.format is! NumericFormat || raw == null) {
        continue;
      }
      if (!raw.isFinite) continue;
      final points = [...?series[id], TrendPoint(at, entry.scaling.apply(raw))];
      series[id] = points.length > maxPoints
          ? points.sublist(points.length - maxPoints)
          : points;
    }
    state = TrendState(selected: state.selected, series: series);
  }

  /// Returns `false` if the selection is already full.
  bool toggle(String entryId) {
    final selected = [...state.selected];
    if (selected.remove(entryId)) {
      state = TrendState(selected: selected, series: state.series);
      return true;
    }
    if (selected.length >= maxSeries) return false;
    state = TrendState(selected: [...selected, entryId], series: state.series);
    return true;
  }

  void clear() => state = TrendState(selected: state.selected);
}

final trendControllerProvider = NotifierProvider<TrendController, TrendState>(
  TrendController.new,
);
