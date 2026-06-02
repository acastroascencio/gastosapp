import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveThemeMode(String mode) async {
    try {
      await _storage.write(key: 'themeMode', value: mode);
    } catch (_) {}
  }

  static Future<String?> getThemeMode() async {
    try {
      return await _storage.read(key: 'themeMode');
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  static Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteString(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}

