// Flutter Web implementation of URL query-parameter rewriting.
//
// ImportPage calls `updateQueryParameter('data', base64url(payload))`
// after every edit so that:
//   1. Refreshing the browser preserves the latest edited state
//   2. Sharing the URL shares the edits, not the original handoff
//
// We use `history.replaceState` so the edit does not pollute browser
// back/forward history. dart:html is still the broadly-supported path
// for Flutter Web; the migration to `package:web` is a separate task.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void updateQueryParameter(String key, String value) {
  try {
    final currentUrl = Uri.parse(html.window.location.href);
    final newQuery = Map<String, String>.from(currentUrl.queryParameters);
    newQuery[key] = value;
    final newUri = currentUrl.replace(queryParameters: newQuery);
    html.window.history.replaceState(null, '', newUri.toString());
  } catch (_) {
    // best-effort; never block editing because URL rewrite failed
  }
}
