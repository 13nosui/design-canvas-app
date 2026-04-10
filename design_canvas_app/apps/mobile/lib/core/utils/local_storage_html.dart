// Flutter Web implementation of localStorage read/write.
//
// Used by CanvasVirtualPages to persist virtual routes across browser
// reloads. dart:html is still the broadly-supported path for Flutter
// Web; the migration to `package:web` is a separate task.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? readLocalStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void writeLocalStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {
    // best-effort; never block the app because storage write failed
  }
}

void removeLocalStorage(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {
    // best-effort
  }
}
