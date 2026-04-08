// Noop stub for non-web platforms. The web implementation lives in
// `url_updater_html.dart` and is picked up via conditional import from
// `import_page.dart`. On macOS / iOS / Android there is no browser URL
// to rewrite, so every call is a safe noop.

void updateQueryParameter(String key, String value) {
  // intentionally empty
}
