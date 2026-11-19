import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/features/settings/domain/app_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/addressing_mode.dart';

class SettingsRepository {
  new(this._store);

  final KeyValueStore _store;

  static const _themeKey = 'settings.theme';
  static const _localeKey = 'settings.locale';
  static const _addressingKey = 'settings.addressingMode';
  static const _confirmWritesKey = 'settings.confirmWrites';
  static const _highlightPlausibleKey = 'settings.highlightPlausible';

  AppSettings load() {
    const defaults = AppSettings();
    final localeCode = _store.getString(_localeKey);
    return AppSettings(
      // Unknown stored values (e.g. from a newer app version) fall back to
      // defaults instead of throwing.
      theme: _enumByName(
        AppThemePreference.values,
        _store.getString(_themeKey),
        defaults.theme,
      ),
      localeOverride: localeCode == null ? null : Locale(localeCode),
      addressingMode: _enumByName(
        AddressingMode.values,
        _store.getString(_addressingKey),
        defaults.addressingMode,
      ),
      confirmWrites:
          _store.getBool(_confirmWritesKey) ?? defaults.confirmWrites,
      highlightPlausible:
          _store.getBool(_highlightPlausibleKey) ?? defaults.highlightPlausible,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _store.setString(_themeKey, settings.theme.name);
    final locale = settings.localeOverride;
    if (locale == null) {
      await _store.remove(_localeKey);
    } else {
      await _store.setString(_localeKey, locale.languageCode);
    }
    await _store.setString(_addressingKey, settings.addressingMode.name);
    await _store.setBool(_confirmWritesKey, value: settings.confirmWrites);
    await _store.setBool(
      _highlightPlausibleKey,
      value: settings.highlightPlausible,
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
);
