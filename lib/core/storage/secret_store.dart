import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Passwords and private keys: never in the JSON documents.
abstract interface class SecretStore {
  Future<String?> read(String key);

  /// `null` deletes the entry.
  Future<void> write(String key, String? value);
}

/// Keychain (macOS/iOS), Keystore-backed storage (Android), libsecret
/// (Linux), DPAPI (Windows).
final class SecureSecretStore implements SecretStore {
  new([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // The data protection keychain needs a keychain-access-group
            // entitlement, i.e. an app signed with a team ID; unsigned
            // builds fail with -34018. The login keychain is encrypted
            // as well and works for every build.
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

final class InMemorySecretStore implements SecretStore {
  new([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());
