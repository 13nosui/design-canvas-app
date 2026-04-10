// ProjectListController — manages the list of projects visible in the
// project bar above the canvas. Each project groups a set of virtual
// routes (screen payloads) under a name + icon. Persisted to
// localStorage so the project list survives browser reload.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/utils/local_storage_stub.dart'
    if (dart.library.html) '../../core/utils/local_storage_html.dart';

const _storageKey = 'canvas_projects';

class ProjectEntry {
  final String slug;
  final String name;
  final String icon;
  final DateTime createdAt;

  const ProjectEntry({
    required this.slug,
    required this.name,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectEntry.fromJson(Map<String, dynamic> json) => ProjectEntry(
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ProjectListController extends ChangeNotifier {
  final List<ProjectEntry> _projects = [];

  /// Currently selected project slug. Null means "All Projects".
  String? _selectedSlug;

  List<ProjectEntry> get projects => List.unmodifiable(_projects);
  String? get selectedSlug => _selectedSlug;
  bool get hasSelection => _selectedSlug != null;

  ProjectEntry? get selectedProject {
    if (_selectedSlug == null) return null;
    return _projects
        .cast<ProjectEntry?>()
        .firstWhere((p) => p?.slug == _selectedSlug, orElse: () => null);
  }

  /// Restore from localStorage. Call once at startup.
  void restoreFromStorage() {
    final raw = readLocalStorage(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _projects.add(ProjectEntry.fromJson(item));
        }
      }
      if (_projects.isNotEmpty) notifyListeners();
    } on FormatException {
      // corrupted data — ignore
    }
  }

  void addProject(ProjectEntry project) {
    // Replace if slug already exists (idempotent)
    _projects.removeWhere((p) => p.slug == project.slug);
    _projects.add(project);
    _persist();
    notifyListeners();
  }

  void removeProject(String slug) {
    final removed = _projects.where((p) => p.slug == slug).toList();
    if (removed.isEmpty) return;
    _projects.removeWhere((p) => p.slug == slug);
    if (_selectedSlug == slug) _selectedSlug = null;
    _persist();
    notifyListeners();
  }

  void renameProject(String slug, String newName) {
    final idx = _projects.indexWhere((p) => p.slug == slug);
    if (idx == -1) return;
    final old = _projects[idx];
    _projects[idx] = ProjectEntry(
      slug: old.slug,
      name: newName,
      icon: old.icon,
      createdAt: old.createdAt,
    );
    _persist();
    notifyListeners();
  }

  /// Select a project to filter the canvas. Pass null for "All Projects".
  void selectProject(String? slug) {
    if (_selectedSlug == slug) return;
    _selectedSlug = slug;
    notifyListeners();
  }

  /// Register a project from a virtual-pages payload (called by
  /// CanvasVirtualPages.addFromPayload → UI layer).
  ProjectEntry createFromPayload(Map<String, dynamic> payload) {
    final title = (payload['title'] as String?) ?? 'Untitled';
    final icon = (payload['icon'] as String?) ?? '';
    final slug = _slugify(title);
    final entry = ProjectEntry(
      slug: slug,
      name: title,
      icon: icon,
      createdAt: DateTime.now(),
    );
    addProject(entry);
    return entry;
  }

  void _persist() {
    if (_projects.isEmpty) {
      removeLocalStorage(_storageKey);
    } else {
      writeLocalStorage(
          _storageKey, jsonEncode(_projects.map((p) => p.toJson()).toList()));
    }
  }
}

String _slugify(String input) {
  final slug = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return slug.isEmpty ? 'untitled' : slug;
}
