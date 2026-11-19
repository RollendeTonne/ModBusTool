import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/features/settings/data/settings_repository.dart';
import 'package:modbus_explorer/features/settings/domain/app_settings.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/addressing_mode.dart';

void main() {
  group('SettingsRepository', () {
    test('returns defaults for an empty store', () {
      final settings = SettingsRepository(InMemoryKeyValueStore()).load();
      expect(settings, const AppSettings());
      expect(settings.addressingMode, AddressingMode.oneBased);
      expect(settings.confirmWrites, isTrue);
      expect(settings.localeOverride, isNull);
    });

    test('round-trips all values', () async {
      final repo = SettingsRepository(InMemoryKeyValueStore());
      const custom = AppSettings(
        theme: AppThemePreference.dark,
        localeOverride: Locale('de'),
        addressingMode: AddressingMode.zeroBased,
        confirmWrites: false,
        highlightPlausible: false,
      );
      await repo.save(custom);
      expect(repo.load(), custom);
    });

    test('clearing the locale override removes the stored value', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);
      await repo.save(const AppSettings(localeOverride: Locale('en')));
      await repo.save(const AppSettings());
      expect(store.getString('settings.locale'), isNull);
      expect(repo.load().localeOverride, isNull);
    });

    test('unknown enum names fall back to defaults', () {
      final repo = SettingsRepository(
        InMemoryKeyValueStore({
          'settings.theme': 'neon',
          'settings.addressingMode': 'twoBased',
        }),
      );
      final settings = repo.load();
      expect(settings.theme, AppThemePreference.system);
      expect(settings.addressingMode, AddressingMode.oneBased);
    });
  });
}
