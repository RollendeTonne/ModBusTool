import 'package:meta/meta.dart';

/// Linear scaling `value * factor + offset`, optionally rounded for display.
@immutable
final class Scaling {
  const new({this.factor = 1, this.offset = 0, this.decimals})
    : assert(decimals == null || decimals >= 0, 'decimals must be >= 0');

  static const identity = Scaling();

  final double factor;
  final double offset;

  /// Fixed number of decimals; `null` shows as many as needed.
  final int? decimals;

  bool get isIdentity => factor == 1 && offset == 0 && decimals == null;

  double apply(double value) => value * factor + offset;

  Scaling copyWith({double? factor, double? offset, int? decimals}) => Scaling(
    factor: factor ?? this.factor,
    offset: offset ?? this.offset,
    decimals: decimals ?? this.decimals,
  );

  @override
  bool operator ==(Object other) =>
      other is Scaling &&
      other.factor == factor &&
      other.offset == offset &&
      other.decimals == decimals;

  @override
  int get hashCode => Object.hash(factor, offset, decimals);
}
