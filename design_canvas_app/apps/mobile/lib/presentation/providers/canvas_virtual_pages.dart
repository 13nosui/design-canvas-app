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

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_system/codegen/page_codegen.dart';
import '../../core/design_system/codegen/page_preview.dart';

class CanvasVirtualPages extends ChangeNotifier {
  final Map<String, _VirtualProject> _projects = {};

  /// All virtual routes currently registered — merged into `canvasRoutes`
  /// by the canvas page.
  List<AppRouteDef> get routes =>
      _projects.values.expand((p) => p.routes).toList();

  /// True when at least one payload has been sent to the canvas.
  bool get isNotEmpty => _projects.isNotEmpty;

  /// Register (or replace) all screens from [payload] as virtual routes.
  /// Returns the number of routes created.
  int addFromPayload(Map<String, dynamic> payload) {
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
      final routeName = '$icon $title / ${page.sourceScreen['name'] ?? page.slug}';
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
    notifyListeners();
    return virtualRoutes.length;
  }

  /// Remove all virtual routes for a given project slug.
  void removeProject(String slug) {
    if (_projects.remove(slug) != null) {
      notifyListeners();
    }
  }

  /// Remove everything.
  void clear() {
    if (_projects.isNotEmpty) {
      _projects.clear();
      notifyListeners();
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
