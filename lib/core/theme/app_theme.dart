import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF0B6E99);

  // No bundled font: the app must work offline in the field, and every
  // platform ships a decent monospace face.
  static const monoFontFamily = 'Menlo';
  static const monoFontFallback = [
    'SF Mono',
    'Consolas',
    'Cascadia Mono',
    'DejaVu Sans Mono',
    'Liberation Mono',
    'Roboto Mono',
    'Droid Sans Mono',
    'monospace',
  ];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      extensions: [AppColors.forBrightness(brightness)],
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
    );
  }
}

extension MonospaceTextStyle on TextStyle {
  /// Fixed-width digits keep hex/binary columns aligned while values change.
  TextStyle get mono => copyWith(
    fontFamily: AppTheme.monoFontFamily,
    fontFamilyFallback: AppTheme.monoFontFallback,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
