import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secrets kept in the iOS Keychain / Android Keystore-backed storage.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore();

  static const _storage = FlutterSecureStorage(
    // Only this device, only while unlocked; never in backups or iCloud.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Every secret of the app: database key, PIN hash, lockout counters.
  Future<void> deleteAll() => _storage.deleteAll();
}

class MemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Database key: 256 random bits, created on first launch.
Future<({String key, bool created})> loadOrCreateDatabaseKey(SecureStore store) async {
  const name = 'db_key_v1';
  final existing = await store.read(name);
  if (existing != null) return (key: existing, created: false);
  final rnd = Random.secure();
  final key = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  await store.write(name, key);
  return (key: key, created: true);
}
