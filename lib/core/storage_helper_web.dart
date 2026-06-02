// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

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

  static void clearUrlParameters() {
    try {
      final uri = Uri.parse(html.window.location.href);
      if (uri.queryParameters.isNotEmpty || uri.fragment.isNotEmpty) {
        final cleanUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 && uri.port != 0 ? ":${uri.port}" : ""}${uri.path}';
        html.window.history.replaceState({}, '', cleanUrl);
      }
    } catch (_) {}
  }
}

