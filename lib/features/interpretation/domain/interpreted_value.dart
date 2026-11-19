import 'package:meta/meta.dart';

enum FloatPrecision { single, double }

enum InvalidReason { insufficientData, invalidBcdDigit, timestampOutOfRange }

/// Result of decoding raw bytes as one data type.
@immutable
sealed class InterpretedValue {
  const new();

  /// Value usable for scaling/plausibility, or `null` if not numeric.
  double? get numericValue;
}

/// Integers are kept as [BigInt] so UINT64 stays exact on every platform.
final class IntegerValue extends InterpretedValue {
  const new(this.value);

  new fromInt(int value) : value = BigInt.from(value);

  final BigInt value;

  @override
  double get numericValue => value.toDouble();

  @override
  bool operator ==(Object other) =>
      other is IntegerValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IntegerValue($value)';
}

final class FloatValue extends InterpretedValue {
  const new(this.value, {required this.precision, this.isDenormal = false});

  final double value;
  final FloatPrecision precision;

  /// Taken from the raw exponent bits: a float32 widened to double is no
  /// longer subnormal, so this can't be derived from [value] afterwards.
  final bool isDenormal;

  @override
  double get numericValue => value;

  @override
  bool operator ==(Object other) =>
      other is FloatValue &&
      other.precision == precision &&
      other.isDenormal == isDenormal &&
      (other.value == value || (other.value.isNaN && value.isNaN));

  @override
  int get hashCode => Object.hash(value.isNaN ? 'NaN' : value, precision);

  @override
  String toString() => 'FloatValue($value, $precision)';
}

final class TimestampValue extends InterpretedValue {
  const new(this.value);

  final DateTime value;

  @override
  double? get numericValue => null;

  @override
  bool operator ==(Object other) =>
      other is TimestampValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TimestampValue(${value.toIso8601String()})';
}

final class TextValue extends InterpretedValue {
  const new(this.text, {required this.hasNonPrintable});

  final String text;

  /// Control characters or bytes not representable in the chosen encoding.
  final bool hasNonPrintable;

  @override
  double? get numericValue => null;

  @override
  bool operator ==(Object other) =>
      other is TextValue &&
      other.text == text &&
      other.hasNonPrintable == hasNonPrintable;

  @override
  int get hashCode => Object.hash(text, hasNonPrintable);

  @override
  String toString() => 'TextValue("$text")';
}

/// A single coil, discrete input or bit of a register.
final class BoolValue extends InterpretedValue {
  const new(this.value);

  final bool value;

  @override
  double get numericValue => value ? 1 : 0;

  @override
  bool operator ==(Object other) => other is BoolValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BoolValue($value)';
}

final class InvalidValue extends InterpretedValue {
  const new(this.reason);

  final InvalidReason reason;

  @override
  double? get numericValue => null;

  @override
  bool operator ==(Object other) =>
      other is InvalidValue && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'InvalidValue($reason)';
}
