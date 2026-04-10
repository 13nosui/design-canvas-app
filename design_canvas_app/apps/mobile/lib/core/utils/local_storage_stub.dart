// Noop stub for non-web platforms. The web implementation lives in
// `local_storage_html.dart` and is picked up via conditional import.
// On macOS / iOS / Android there is no localStorage, so every call is
// a safe noop.

String? readLocalStorage(String key) => null;

void writeLocalStorage(String key, String value) {
  // intentionally empty
}

void removeLocalStorage(String key) {
  // intentionally empty
}
