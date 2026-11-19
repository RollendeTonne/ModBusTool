import 'package:material_ui/material_ui.dart';

/// Semantic colours used consistently across tables, matrix and monitor.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.changed,
    required this.onChanged,
    required this.implausible,
    required this.plausible,
    required this.tx,
    required this.rx,
    required this.success,
    required this.warning,
  });

  factory forBrightness(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  // Shades chosen for >= 4.5:1 contrast against the respective surfaces.
  static const light = AppColors(
    changed: Color(0xFFFFE08A),
    onChanged: Color(0xFF3D2E00),
    implausible: Color(0xFF666666),
    plausible: Color(0xFF1B6E2E),
    tx: Color(0xFF1155AA),
    rx: Color(0xFF7A3E9D),
    success: Color(0xFF1B6E2E),
    warning: Color(0xFF9A5B00),
  );

  static const dark = AppColors(
    changed: Color(0xFF6B5300),
    onChanged: Color(0xFFFFF1C2),
    implausible: Color(0xFF8F8F8F),
    plausible: Color(0xFF7FD992),
    tx: Color(0xFF8AB8FF),
    rx: Color(0xFFD7A6F2),
    success: Color(0xFF7FD992),
    warning: Color(0xFFFFC266),
  );

  /// Background for values that changed since the previous poll.
  final Color changed;
  final Color onChanged;

  /// Text colour for NaN/Inf/absurd interpretations (dimmed, not alarming).
  final Color implausible;
  final Color plausible;
  final Color tx;
  final Color rx;
  final Color success;
  final Color warning;

  @override
  AppColors copyWith({
    Color? changed,
    Color? onChanged,
    Color? implausible,
    Color? plausible,
    Color? tx,
    Color? rx,
    Color? success,
    Color? warning,
  }) => AppColors(
    changed: changed ?? this.changed,
    onChanged: onChanged ?? this.onChanged,
    implausible: implausible ?? this.implausible,
    plausible: plausible ?? this.plausible,
    tx: tx ?? this.tx,
    rx: rx ?? this.rx,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      changed: Color.lerp(changed, other.changed, t)!,
      onChanged: Color.lerp(onChanged, other.onChanged, t)!,
      implausible: Color.lerp(implausible, other.implausible, t)!,
      plausible: Color.lerp(plausible, other.plausible, t)!,
      tx: Color.lerp(tx, other.tx, t)!,
      rx: Color.lerp(rx, other.rx, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ??
      AppColors.forBrightness(Theme.of(this).brightness);
}
