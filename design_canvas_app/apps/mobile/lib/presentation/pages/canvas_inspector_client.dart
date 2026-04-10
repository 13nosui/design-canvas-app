// CanvasInspectorClient — thin transport abstraction in front of the
// local inspector backend (http://localhost:8080/inspector/*). Extracted
// so `CanvasEditorController` can be exercised in pure Dart tests with a
// fake client — no HTTP, no dart:io, no Flutter bindings required.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Outcome of a single inspector backend call.
///
/// We model this as a simple value class rather than a sealed type
/// because the caller almost always branches on [ok] plus an optional
/// [error] string, and the optional [data] for parse results.
class InspectorResult {
  const InspectorResult.ok({this.data}) : ok = true, error = null;
  const InspectorResult.failure(this.error) : ok = false, data = null;

  final bool ok;
  final String? error;
  final Map<String, dynamic>? data;
}

/// Abstract interface for all inspector operations used by
/// [CanvasEditorController]. Implementations should be side-effect only
/// — they should not notify listeners or touch Flutter state.
abstract interface class CanvasInspectorClient {
  Future<InspectorResult> parse(String stylesPath);
  Future<InspectorResult> updateStyle({
    required String path,
    required String? className,
    required String name,
    required String value,
  });
  Future<InspectorResult> promoteToken({
    required String path,
    required String? className,
    required String name,
    required String tokenName,
    required String value,
  });
  Future<InspectorResult> replaceText({
    required String path,
    required String id,
    required String text,
  });
  Future<InspectorResult> wrap({
    required String path,
    required String id,
    required String wrapper,
  });
  Future<InspectorResult> unwrap({
    required String path,
    required String id,
  });
  Future<InspectorResult> duplicate({
    required String path,
    required String id,
  });
  Future<InspectorResult> insert({
    required String path,
    required String id,
  });
}

/// Production implementation that talks to the local inspector server
/// over HTTP. Base URL defaults to `http://localhost:8080` so that
/// existing behaviour is preserved byte-for-byte after extraction.
class HttpCanvasInspectorClient implements CanvasInspectorClient {
  HttpCanvasInspectorClient({
    http.Client? httpClient,
    String baseUrl = 'http://localhost:8080',
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<InspectorResult> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _httpClient.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return const InspectorResult.ok();
      }
      return InspectorResult.failure(_extractError(res.body));
    } on Exception catch (e) {
      return InspectorResult.failure(e.toString());
    }
  }

  static String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // fall through
    }
    return body;
  }

  @override
  Future<InspectorResult> parse(String stylesPath) async {
    try {
      final res = await _httpClient
          .get(Uri.parse('$_baseUrl/inspector/parse?path=$stylesPath'));
      if (res.statusCode != 200) {
        return InspectorResult.failure(_extractError(res.body));
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const InspectorResult.failure('Unexpected parse response shape');
      }
      return InspectorResult.ok(data: decoded);
    } on Exception catch (e) {
      return InspectorResult.failure(e.toString());
    }
  }

  @override
  Future<InspectorResult> updateStyle({
    required String path,
    required String? className,
    required String name,
    required String value,
  }) =>
      _post('/inspector/update', {
        'path': path,
        'className': className,
        'name': name,
        'value': value,
      });

  @override
  Future<InspectorResult> promoteToken({
    required String path,
    required String? className,
    required String name,
    required String tokenName,
    required String value,
  }) =>
      _post('/inspector/promote', {
        'path': path,
        'className': className,
        'name': name,
        'tokenName': tokenName,
        'value': value,
      });

  @override
  Future<InspectorResult> replaceText({
    required String path,
    required String id,
    required String text,
  }) =>
      _post('/inspector/replace_text', {
        'path': path,
        'id': id,
        'text': text,
      });

  @override
  Future<InspectorResult> wrap({
    required String path,
    required String id,
    required String wrapper,
  }) =>
      _post('/inspector/wrap', {
        'path': path,
        'id': id,
        'wrapper': wrapper,
      });

  @override
  Future<InspectorResult> unwrap({
    required String path,
    required String id,
  }) =>
      _post('/inspector/unwrap', {'path': path, 'id': id});

  @override
  Future<InspectorResult> duplicate({
    required String path,
    required String id,
  }) =>
      _post('/inspector/duplicate', {'path': path, 'id': id});

  @override
  Future<InspectorResult> insert({
    required String path,
    required String id,
  }) =>
      _post('/inspector/insert', {'path': path, 'id': id});
}
