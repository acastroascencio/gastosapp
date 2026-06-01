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
}
