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
}
