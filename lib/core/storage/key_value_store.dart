import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value persistence for small settings.
///
/// Wrapping shared_preferences keeps repositories testable without
/// platform channels.
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, {required bool value});
  Future<void> remove(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPreferencesStore> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return SharedPreferencesStore(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class InMemoryKeyValueStore implements KeyValueStore {
  new([Map<String, Object>? initial]) : _values = {...?initial};

  final Map<String, Object> _values;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

/// Must be overridden in `main` once the store is initialised.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('keyValueStoreProvider not overridden'),
);
