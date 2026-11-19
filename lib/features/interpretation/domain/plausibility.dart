import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/float_utils.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';

enum Plausibility { implausible, neutral, plausible }

enum PlausibilityIssue {
  notANumber,
  infinite,
  denormalized,
  hugeMagnitude,
  tinyMagnitude,
  manyDigits,
  dateOutOfRange,
  nonPrintable,
  invalid,
}

@immutable
final class PlausibilityAssessment {
  const new(this.level, [this.issue]);

  final Plausibility level;

  /// Why a value was judged implausible (for tooltips).
  final PlausibilityIssue? issue;

  @override
  bool operator ==(Object other) =>
      other is PlausibilityAssessment &&
      other.level == level &&
      other.issue == issue;

  @override
  int get hashCode => Object.hash(level, issue);

  @override
  String toString() => 'PlausibilityAssessment($level, $issue)';
}

const _neutral = PlausibilityAssessment(Plausibility.neutral);
const _plausible = PlausibilityAssessment(Plausibility.plausible);

/// Heuristic thresholds. Field devices rarely report values beyond these,
/// while wrongly ordered bytes almost always land outside them.
abstract final class PlausibilityThresholds {
  static const maxPlausibleFloat = 1e7;
  static const minPlausibleFloat = 1e-3;
  static const maxSaneFloat = 1e12;
  static const minSaneFloat = 1e-9;
  static const maxPlausibleInteger = 10000000;
  static const maxSaneInteger = 1000000000000;

  /// Measured values have few decimals; byte garbage uses all available.
  static const maxDecimals = 4;
  static final earliestPlausibleDate = DateTime.utc(2000);
  static final latestPlausibleDate = DateTime.utc(2100);

  /// Only dates close to today count as plausible: floats between ~2 and
  /// ~1000 read as UNIX32 always land in 2004–2014 and would otherwise be
  /// highlighted (seen on a real device screen).
  static const recentPast = Duration(days: 3653); // ~10 years
  static const nearFuture = Duration(days: 731); // ~2 years
}

/// Classifies how likely [value] is the intended interpretation of [type].
PlausibilityAssessment assessPlausibility(
  InterpretedValue value,
  DataType type, {
  DateTime? now,
}) => switch (value) {
  BoolValue() => _neutral,
  InvalidValue() => const PlausibilityAssessment(
    Plausibility.implausible,
    PlausibilityIssue.invalid,
  ),
  FloatValue() => _assessFloat(value),
  IntegerValue() => _assessInteger(value.value, type),
  TimestampValue() => _assessTimestamp(value.value, now ?? DateTime.now()),
  TextValue() =>
    value.hasNonPrintable
        ? const PlausibilityAssessment(
            Plausibility.implausible,
            PlausibilityIssue.nonPrintable,
          )
        : value.text.isEmpty
        ? _neutral
        : _plausible,
};

PlausibilityAssessment _assessFloat(FloatValue float) {
  final v = float.value;
  PlausibilityAssessment implausible(PlausibilityIssue issue) =>
      PlausibilityAssessment(Plausibility.implausible, issue);

  if (v.isNaN) return implausible(PlausibilityIssue.notANumber);
  if (v.isInfinite) return implausible(PlausibilityIssue.infinite);
  if (float.isDenormal) return implausible(PlausibilityIssue.denormalized);
  if (v == 0) return _neutral;
  final magnitude = v.abs();
  if (magnitude > PlausibilityThresholds.maxSaneFloat) {
    return implausible(PlausibilityIssue.hugeMagnitude);
  }
  if (magnitude < PlausibilityThresholds.minSaneFloat) {
    return implausible(PlausibilityIssue.tinyMagnitude);
  }
  if (magnitude > PlausibilityThresholds.maxPlausibleFloat ||
      magnitude < PlausibilityThresholds.minPlausibleFloat) {
    return _neutral;
  }
  return _hasFewDecimals(float)
      ? _plausible
      : const PlausibilityAssessment(
          Plausibility.neutral,
          PlausibilityIssue.manyDigits,
        );
}

/// True if a short decimal (≤ 4 places) rounds to exactly this float, i.e.
/// the value was most likely written as e.g. `230.1`, not random bits.
bool _hasFewDecimals(FloatValue float) {
  final v = float.value;
  for (var places = 0; places <= PlausibilityThresholds.maxDecimals; places++) {
    final candidate = double.parse(v.toStringAsFixed(places));
    final roundTrip = float.precision == FloatPrecision.single
        ? toFloat32(candidate)
        : candidate;
    if (roundTrip == v) return true;
  }
  return false;
}

PlausibilityAssessment _assessInteger(BigInt value, DataType type) {
  // Every 16-bit pattern is a reasonable integer; there is no signal.
  if (type.byteWidth <= 2 && type != DataType.bcd16) return _neutral;
  // Valid BCD is weak evidence: every register whose hex digits are all
  // 0–9 qualifies. Only invalid BCD (handled as InvalidValue) is a signal.
  if (type == DataType.bcd16 || type == DataType.bcd32) return _neutral;
  if (value == BigInt.zero) return _neutral;
  final magnitude = value.abs();
  if (magnitude > BigInt.from(PlausibilityThresholds.maxSaneInteger)) {
    return const PlausibilityAssessment(
      Plausibility.implausible,
      PlausibilityIssue.hugeMagnitude,
    );
  }
  if (magnitude <= BigInt.from(PlausibilityThresholds.maxPlausibleInteger)) {
    return _plausible;
  }
  return _neutral;
}

PlausibilityAssessment _assessTimestamp(DateTime value, DateTime now) {
  if (value.millisecondsSinceEpoch == 0) return _neutral;
  final inRange =
      !value.isBefore(PlausibilityThresholds.earliestPlausibleDate) &&
      value.isBefore(PlausibilityThresholds.latestPlausibleDate);
  if (!inRange) {
    return const PlausibilityAssessment(
      Plausibility.implausible,
      PlausibilityIssue.dateOutOfRange,
    );
  }
  final recent =
      value.isAfter(now.subtract(PlausibilityThresholds.recentPast)) &&
      value.isBefore(now.add(PlausibilityThresholds.nearFuture));
  return recent ? _plausible : _neutral;
}
