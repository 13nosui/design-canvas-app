// ImportPayloadController — the "payload is truth" state model for
// ImportPage. Owns the editable payload, undo/redo history, and all
// mutation helpers. Exposed as a ChangeNotifier so the widget tree can
// subscribe and rebuild.
//
// This separation (ADR-0006) lets the UI stay thin (display + wire
// callbacks) while the state logic is testable in pure Dart without
// Flutter bindings.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/utils/url_updater_stub.dart'
    if (dart.library.html) '../../core/utils/url_updater_html.dart';

class ImportPayloadController extends ChangeNotifier {
  ImportPayloadController(Map<String, dynamic>? initial)
      : _payload = initial;

  Map<String, dynamic>? _payload;
  Map<String, dynamic>? get payload => _payload;

  bool _dirty = false;
  bool get dirty => _dirty;

  /// Bounded undo/redo stacks of deep-cloned payload snapshots.
  /// `_undoStack.last` is the state BEFORE the latest mutation; popping
  /// it restores the previous payload.
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  static const int _historyLimit = 30;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushHistory() {
    final p = _payload;
    if (p == null) return;
    _undoStack.add(_deepClone(p));
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  Map<String, dynamic> _deepClone(Map<String, dynamic> src) {
    // Payload is guaranteed JSON-safe (base64url(json) on the way in),
    // so round-tripping through JSON is both correct and cheap.
    return json.decode(json.encode(src)) as Map<String, dynamic>;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final current = _payload;
    if (current == null) return;
    _redoStack.add(_deepClone(current));
    if (_redoStack.length > _historyLimit) _redoStack.removeAt(0);
    _payload = _undoStack.removeLast();
    _persistToUrl();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = _payload;
    if (current == null) return;
    _undoStack.add(_deepClone(current));
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    _payload = _redoStack.removeLast();
    _persistToUrl();
    notifyListeners();
  }

  /// Apply an edit at a nested path within the payload. `path` accepts
  /// `String` for map keys and `int` for list indices.
  void editAtPath(List<Object> path, String newValue) {
    final payload = _payload;
    if (payload == null || path.isEmpty) return;
    _pushHistory();
    dynamic current = payload;
    for (var i = 0; i < path.length - 1; i++) {
      final key = path[i];
      if (current is Map && key is String) {
        current = current[key];
      } else if (current is List && key is int) {
        current = current[key];
      } else {
        return;
      }
    }
    final last = path.last;
    if (current is Map && last is String) {
      current[last] = newValue;
    } else if (current is List && last is int) {
      current[last] = newValue;
    }
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  // ---------- Structural mutations ----------

  void startBlank() {
    _pushHistory();
    _payload = <String, dynamic>{
      'title': '新規プロジェクト',
      'icon': '✨',
      'summary': '1〜2 行の概要',
      'prompt': '(手動作成)',
      'meta': <Map<String, dynamic>>[],
      'detail': <String, dynamic>{
        'screens': <Map<String, dynamic>>[
          {
            'name': 'ホーム',
            'purpose': 'この画面の目的',
            'sections': <Map<String, dynamic>>[
              {'label': 'アクション', 'body': 'ユーザーがここで取れる操作'},
              {'label': '表示情報', 'body': 'この画面に表示するデータ'},
            ],
          },
        ],
        'userFlow': '',
        'apis': <Map<String, dynamic>>[],
        'stack': <String>[],
        'risks': <String>[],
      },
    };
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  List<dynamic>? _ensureScreensList() {
    final payload = _payload;
    if (payload == null) return null;
    var detail = payload['detail'];
    if (detail is! Map<String, dynamic>) {
      detail = <String, dynamic>{};
      payload['detail'] = detail;
    }
    var screens = (detail as Map<String, dynamic>)['screens'];
    if (screens is! List) {
      screens = <dynamic>[];
      detail['screens'] = screens;
    } else if (screens is! List<dynamic>) {
      screens = screens.toList();
      detail['screens'] = screens;
    }
    return screens as List<dynamic>;
  }

  List<dynamic>? _ensureSectionsList(int screenIndex) {
    final screens = _ensureScreensList();
    if (screens == null || screenIndex < 0 || screenIndex >= screens.length) {
      return null;
    }
    final screen = screens[screenIndex];
    if (screen is! Map<String, dynamic>) return null;
    var sections = screen['sections'];
    if (sections is! List) {
      sections = <Map<String, dynamic>>[];
      screen['sections'] = sections;
    } else if (sections is! List<dynamic>) {
      sections = sections.toList();
      screen['sections'] = sections;
    }
    return sections as List<dynamic>;
  }

  List<dynamic>? _ensureDetailList(String key) {
    final payload = _payload;
    if (payload == null) return null;
    var detail = payload['detail'];
    if (detail is! Map<String, dynamic>) {
      detail = <String, dynamic>{};
      payload['detail'] = detail;
    }
    var list = (detail as Map<String, dynamic>)[key];
    if (list is! List) {
      list = <dynamic>[];
      detail[key] = list;
    } else if (list is! List<dynamic>) {
      list = list.toList();
      detail[key] = list;
    }
    return list as List<dynamic>;
  }

  void addScreen() {
    _pushHistory();
    final screens = _ensureScreensList();
    if (screens == null) return;
    screens.add(<String, dynamic>{
      'name': '新規画面',
      'purpose': 'この画面で何ができるかを書く',
      'sections': <Map<String, dynamic>>[
        {'label': 'アクション', 'body': 'ユーザーがここで取れる操作'},
        {'label': '表示情報', 'body': 'この画面に表示するデータ'},
      ],
    });
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void removeScreen(int index) {
    _pushHistory();
    final screens = _ensureScreensList();
    if (screens == null || index < 0 || index >= screens.length) return;
    screens.removeAt(index);
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void addSection(int screenIndex) {
    _pushHistory();
    final sections = _ensureSectionsList(screenIndex);
    if (sections == null) return;
    sections.add(<String, dynamic>{'label': 'ラベル', 'body': '本文'});
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void removeSection(int screenIndex, int sectionIndex) {
    _pushHistory();
    final sections = _ensureSectionsList(screenIndex);
    if (sections == null ||
        sectionIndex < 0 ||
        sectionIndex >= sections.length) {
      return;
    }
    sections.removeAt(sectionIndex);
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void addApi() {
    _pushHistory();
    final apis = _ensureDetailList('apis');
    if (apis == null) return;
    apis.add(<String, dynamic>{
      'name': 'GET /endpoint',
      'description': 'この API が返すもの',
    });
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void removeApi(int index) {
    _pushHistory();
    final apis = _ensureDetailList('apis');
    if (apis == null || index < 0 || index >= apis.length) return;
    apis.removeAt(index);
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void addStack() {
    _pushHistory();
    final stack = _ensureDetailList('stack');
    if (stack == null) return;
    stack.add('新規項目');
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void removeStack(int index) {
    _pushHistory();
    final stack = _ensureDetailList('stack');
    if (stack == null || index < 0 || index >= stack.length) return;
    stack.removeAt(index);
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void addRisk() {
    _pushHistory();
    final risks = _ensureDetailList('risks');
    if (risks == null) return;
    risks.add('新しいリスク / 論点');
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  void removeRisk(int index) {
    _pushHistory();
    final risks = _ensureDetailList('risks');
    if (risks == null || index < 0 || index >= risks.length) return;
    risks.removeAt(index);
    _dirty = true;
    _persistToUrl();
    notifyListeners();
  }

  /// Re-encode payload to base64url and update the browser URL (web only).
  /// Best-effort — never throws.
  void _persistToUrl() {
    final payload = _payload;
    if (payload == null) return;
    try {
      final jsonStr = json.encode(payload);
      final base64 =
          base64Url.encode(utf8.encode(jsonStr)).replaceAll('=', '');
      updateQueryParameter('data', base64);
    } catch (_) {
      // swallow
    }
  }
}
