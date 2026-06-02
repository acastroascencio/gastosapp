import 'dart:html' as html;

class StorageHelper {
  static Future<void> saveThemeMode(String mode) async {
    try {
      html.window.localStorage['themeMode'] = mode;
    } catch (_) {}
  }

  static Future<String?> getThemeMode() async {
    try {
      return html.window.localStorage['themeMode'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveString(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static Future<String?> getString(String key) async {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteString(String key) async {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}

