// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<String?> read(String key) async {
  return html.window.localStorage[key];
}

Future<void> write(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> remove(String key) async {
  html.window.localStorage.remove(key);
}

Future<void> clearAll() async {
  html.window.localStorage.clear();
}
