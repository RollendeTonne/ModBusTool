import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/features/settings/data/settings_repository.dart';
import 'package:modbus_explorer/features/settings/domain/app_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/addressing_mode.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> setTheme(AppThemePreference theme) =>
      _update(state.copyWith(theme: theme));

  Future<void> setLocaleOverride(Locale? locale) =>
      _update(state.copyWith(localeOverride: () => locale));

  Future<void> setAddressingMode(AddressingMode mode) =>
      _update(state.copyWith(addressingMode: mode));

  Future<void> setConfirmWrites({required bool enabled}) =>
      _update(state.copyWith(confirmWrites: enabled));

  Future<void> setHighlightPlausible({required bool enabled}) =>
      _update(state.copyWith(highlightPlausible: enabled));

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
