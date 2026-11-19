import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // WCAG AA: 4.5:1 for normal text.
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('$name theme', () {
      final colors = theme.extension<AppColors>()!;
      final surface = theme.colorScheme.surface;
      final textColors = {
        'implausible': colors.implausible,
        'plausible': colors.plausible,
        'tx': colors.tx,
        'rx': colors.rx,
        'success': colors.success,
        'warning': colors.warning,
        'error': theme.colorScheme.error,
      };
      for (final MapEntry(key: label, value: color) in textColors.entries) {
        test('$label text on surface ≥ 4.5:1', () {
          expect(contrast(color, surface), greaterThanOrEqualTo(4.5));
        });
      }

      test('changed highlight keeps text readable', () {
        expect(
          contrast(theme.colorScheme.onSurface, colors.changed),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onChanged, colors.changed),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }
}
