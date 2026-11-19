import 'package:flutter/widgets.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';

enum AppThemePreference { system, light, dark }

@immutable
class AppSettings {
  const new({
    this.theme = AppThemePreference.system,
    this.localeOverride,
    this.addressingMode = AddressingMode.oneBased,
    this.confirmWrites = true,
    this.highlightPlausible = true,
  });

  final AppThemePreference theme;

  /// `null` follows the system language.
  final Locale? localeOverride;
  final AddressingMode addressingMode;
  final bool confirmWrites;
  final bool highlightPlausible;

  AppSettings copyWith({
    AppThemePreference? theme,
    ValueGetter<Locale?>? localeOverride,
    AddressingMode? addressingMode,
    bool? confirmWrites,
    bool? highlightPlausible,
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeOverride: localeOverride != null
        ? localeOverride()
        : this.localeOverride,
    addressingMode: addressingMode ?? this.addressingMode,
    confirmWrites: confirmWrites ?? this.confirmWrites,
    highlightPlausible: highlightPlausible ?? this.highlightPlausible,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.localeOverride == localeOverride &&
      other.addressingMode == addressingMode &&
      other.confirmWrites == confirmWrites &&
      other.highlightPlausible == highlightPlausible;

  @override
  int get hashCode => Object.hash(
    theme,
    localeOverride,
    addressingMode,
    confirmWrites,
    highlightPlausible,
  );
}
