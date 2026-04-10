// CanvasVirtualPages — in-memory route registry that lets ImportPage
// push generated pages onto the design canvas without writing files to
// disk or regenerating scanned_routes.
//
// Usage:
//   ImportPage → "キャンバスに送る" → CanvasVirtualPages.addFromPayload()
//   DesignCanvasPage → merges canvasRoutes + virtualPages.routes
//
// Each payload produces one virtual route group (prefixed /virtual/),
// using GeneratedPagePreview as the live builder. Adding a payload with
// the same project slug replaces the previous version (idempotent).
//
// Persistence: on web, payloads are saved to localStorage so they
// survive browser reload. Call `restoreFromStorage()` once at startup.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_system/codegen/page_codegen.dart';
import '../../core/design_system/codegen/page_preview.dart';
import '../../core/utils/local_storage_stub.dart'
    if (dart.library.html) '../../core/utils/local_storage_html.dart';

/// localStorage key used to persist virtual payloads.
const _storageKey = 'canvas_virtual_payloads';

class CanvasVirtualPages extends ChangeNotifier {
  final Map<String, _VirtualProject> _projects = {};

  /// Raw payloads keyed by project slug — kept in sync with [_projects]
  /// so we can round-trip to localStorage without re-generating routes.
  final Map<String, Map<String, dynamic>> _payloads = {};

  /// All virtual routes currently registered — merged into `canvasRoutes`
  /// by the canvas page.
  List<AppRouteDef> get routes =>
      _projects.values.expand((p) => p.routes).toList();

  /// True when at least one payload has been sent to the canvas.
  bool get isNotEmpty => _projects.isNotEmpty;

  /// Restore previously persisted payloads from localStorage. Call once
  /// at app startup (after the provider is created). On non-web
  /// platforms this is a no-op (readLocalStorage returns null).
  void restoreFromStorage() {
    final raw = readLocalStorage(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      for (final entry in decoded.entries) {
        if (entry.value is Map<String, dynamic>) {
          _addPayloadInternal(entry.value as Map<String, dynamic>,
              persist: false);
        }
      }
      if (_projects.isNotEmpty) notifyListeners();
    } on FormatException {
      // corrupted data — discard silently
    }
  }

  /// Register (or replace) all screens from [payload] as virtual routes.
  /// Returns the number of routes created.
  int addFromPayload(Map<String, dynamic> payload) {
    final count = _addPayloadInternal(payload, persist: true);
    if (count > 0) notifyListeners();
    return count;
  }

  int _addPayloadInternal(
    Map<String, dynamic> payload, {
    required bool persist,
  }) {
    final pages = generatePagesFromPayload(payload);
    if (pages.isEmpty) return 0;

    final title = (payload['title'] as String?) ?? '';
    final icon = (payload['icon'] as String?) ?? '';
    final meta = _asListOfMaps(payload['meta']);
    final detail = payload['detail'] as Map<String, dynamic>? ?? {};
    final apis = _asListOfMaps(detail['apis']);
    final stack = _asListOfStrings(detail['stack']);
    final projectSlug = _slugify(title, fallback: 'untitled');

    final virtualRoutes = <AppRouteDef>[];
    for (final page in pages) {
      final routePath = '/virtual/$projectSlug/${page.slug}';
      final routeName =
          '$icon $title / ${page.sourceScreen['name'] ?? page.slug}';
      virtualRoutes.add(AppRouteDef(
        routePath,
        routeName,
        (context) => GeneratedPagePreview(
          screen: page.sourceScreen,
          projectTitle: title,
          icon: icon,
          meta: meta,
          apis: apis,
          stack: stack,
        ),
        const [],
        const [],
        null,
      ));
    }

    _projects[projectSlug] = _VirtualProject(
      slug: projectSlug,
      title: title,
      routes: virtualRoutes,
    );
    _payloads[projectSlug] = payload;
    if (persist) _persist();
    return virtualRoutes.length;
  }

  /// Remove all virtual routes for a given project slug.
  void removeProject(String slug) {
    if (_projects.remove(slug) != null) {
      _payloads.remove(slug);
      _persist();
      notifyListeners();
    }
  }

  /// Remove everything.
  void clear() {
    if (_projects.isNotEmpty) {
      _projects.clear();
      _payloads.clear();
      _persist();
      notifyListeners();
    }
  }

  void _persist() {
    if (_payloads.isEmpty) {
      removeLocalStorage(_storageKey);
    } else {
      writeLocalStorage(_storageKey, jsonEncode(_payloads));
    }
  }
}

class _VirtualProject {
  final String slug;
  final String title;
  final List<AppRouteDef> routes;
  const _VirtualProject({
    required this.slug,
    required this.title,
    required this.routes,
  });
}

// ── helpers (mirrors page_codegen.dart private helpers) ──────────────

String _slugify(String input, {String fallback = 'untitled'}) {
  final slug = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return slug.isEmpty ? fallback : slug;
}

List<Map<String, dynamic>> _asListOfMaps(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

List<String> _asListOfStrings(dynamic raw) {
  if (raw is List) {
    return raw.whereType<String>().toList();
  }
  return const [];
}
