// CanvasEditorController — the "inspector + AST mutation" state owner
// for DesignCanvasPage, following the same ChangeNotifier pattern as
// ImportPayloadController (see ADR-0007).
//
// Goals of this extraction:
//   1. Get design_canvas_page.dart under the 800-line rule by moving
//      state + side-effect logic out of the widget.
//   2. Make inspector behaviour testable in pure Dart — no Flutter
//      bindings, no BuildContext, no HTTP — by delegating all transport
//      to [CanvasInspectorClient].
//   3. Decouple user feedback (SnackBars) from state mutation via a
//      broadcast event stream the widget subscribes to.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'canvas_inspector_client.dart';

/// User-facing feedback event emitted by [CanvasEditorController].
/// The widget layer translates these into SnackBars — the controller
/// itself never touches BuildContext.
sealed class CanvasEditorEvent {
  const CanvasEditorEvent(this.message);
  final String message;
}

final class CanvasEditorSuccess extends CanvasEditorEvent {
  const CanvasEditorSuccess(super.message);
}

/// Used for "soft failures" where the user tried something the backend
/// can't do (e.g. unwrap a widget that has no parent). Rendered as a
/// warning-coloured SnackBar in the UI.
final class CanvasEditorWarning extends CanvasEditorEvent {
  const CanvasEditorWarning(super.message);
}

final class CanvasEditorError extends CanvasEditorEvent {
  const CanvasEditorError(super.message);
}

class CanvasEditorController extends ChangeNotifier {
  CanvasEditorController({
    required CanvasInspectorClient client,
    String fallbackDartPath = 'lib/ui/page/feed/feed_page.dart',
  })  : _client = client,
        _fallbackDartPath = fallbackDartPath;

  final CanvasInspectorClient _client;
  final String _fallbackDartPath;
  final StreamController<CanvasEditorEvent> _events =
      StreamController<CanvasEditorEvent>.broadcast();

  /// Broadcast stream of UI feedback events. The widget should listen
  /// in initState and cancel in dispose.
  Stream<CanvasEditorEvent> get events => _events.stream;

  String? _inspectedFilePath;
  String? get inspectedFilePath => _inspectedFilePath;

  List<dynamic> _inspectedFields = const [];
  List<dynamic> get inspectedFields => _inspectedFields;

  bool _isInspectorLoading = false;
  bool get isInspectorLoading => _isInspectorLoading;

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }

  /// The `.dart` file the user is currently editing. Inspector paths
  /// are stored as `.styles.dart`; mutation endpoints want the `.dart`
  /// counterpart. Falls back to [_fallbackDartPath] when nothing is
  /// inspected yet so hotkeys still land somewhere sensible.
  String get _dartPath {
    final inspected = _inspectedFilePath;
    if (inspected == null) return _fallbackDartPath;
    return inspected.replaceFirst('.styles.dart', '.dart');
  }

  Future<void> loadInspector(String dartFilePath) async {
    final stylesPath = dartFilePath.replaceFirst('.dart', '.styles.dart');
    _inspectedFilePath = stylesPath;
    _inspectedFields = const [];
    _isInspectorLoading = true;
    notifyListeners();

    final result = await _client.parse(stylesPath);
    _isInspectorLoading = false;
    if (result.ok) {
      final fields = result.data?['fields'];
      _inspectedFields = fields is List ? fields : const [];
    }
    notifyListeners();
  }

  Future<void> updateStyleField(
    String? className,
    String name,
    String newValue,
  ) async {
    final path = _inspectedFilePath;
    if (path == null) return;
    final result = await _client.updateStyle(
      path: path,
      className: className,
      name: name,
      value: newValue,
    );
    if (!result.ok) {
      _emit(CanvasEditorError('Update failed: ${result.error ?? 'unknown'}'));
      return;
    }
    // Re-parse so in-memory state reflects the saved change.
    await loadInspector(_dartPath);
    _emit(const CanvasEditorSuccess(
      '✨ Style saved! Please press "R" (Shift+r) in terminal for Hot Restart.',
    ));
  }

  Future<void> promoteToken(
    String? className,
    String name,
    String? tokenName,
    String value,
  ) async {
    final path = _inspectedFilePath;
    if (path == null || tokenName == null) return;
    final result = await _client.promoteToken(
      path: path,
      className: className,
      name: name,
      tokenName: tokenName,
      value: value,
    );
    if (!result.ok) {
      _emit(CanvasEditorError('Promote failed: ${result.error ?? 'unknown'}'));
      return;
    }
    _emit(const CanvasEditorSuccess('✨ Elevated to AppTokens!'));
    await loadInspector(_dartPath);
  }

  Future<void> updateCodeText(String id, String newText) async {
    // Text widgets always live in the main `.dart` file, even when we
    // arrived here via a `.styles.dart` inspection target.
    var path = _inspectedFilePath ?? _fallbackDartPath;
    if (id.startsWith('__Text__') && path.endsWith('.styles.dart')) {
      path = path.replaceFirst('.styles.dart', '.dart');
    }
    final result =
        await _client.replaceText(path: path, id: id, text: newText);
    if (result.ok) {
      _emit(const CanvasEditorSuccess(
        '✅ Text updated! Please press "r" in terminal for Hot Reload.',
      ));
    } else {
      _emit(CanvasEditorError('❌ Error: ${result.error ?? 'unknown'}'));
    }
  }

  Future<void> wrapComponent(String? selectedId, String wrapperType) async {
    if (selectedId == null) return;
    final result = await _client.wrap(
      path: _dartPath,
      id: selectedId,
      wrapper: wrapperType,
    );
    if (result.ok) {
      _emit(CanvasEditorSuccess('📦 Wrapped with $wrapperType successfully!'));
    } else {
      _emit(CanvasEditorError(
          '❌ Error wrapping: ${result.error ?? 'unknown'}'));
    }
  }

  Future<void> unwrapComponent(String? selectedId) async {
    if (selectedId == null) return;
    final result = await _client.unwrap(path: _dartPath, id: selectedId);
    if (result.ok) {
      _emit(const CanvasEditorSuccess('🔓 Unwrapped successfully!'));
    } else {
      // Unwrap failures are user-visible but expected (e.g. nothing to
      // unwrap). Render as a warning, not a hard error.
      _emit(CanvasEditorWarning(
          '❌ Error unwrapping: ${result.error ?? 'unknown'}'));
    }
  }

  Future<void> duplicateComponent(String? selectedId) async {
    if (selectedId == null) return;
    final result = await _client.duplicate(path: _dartPath, id: selectedId);
    if (result.ok) {
      _emit(const CanvasEditorSuccess('👯 Duplicated successfully!'));
    } else {
      _emit(CanvasEditorWarning(
          '❌ Cannot duplicate: ${result.error ?? 'unknown'}'));
    }
  }

  Future<void> insertComponent(String? selectedId) async {
    if (selectedId == null) return;
    final result = await _client.insert(path: _dartPath, id: selectedId);
    if (result.ok) {
      _emit(const CanvasEditorSuccess('✨ Inserted new element successfully!'));
    } else {
      _emit(CanvasEditorWarning(
          '❌ Cannot insert: ${result.error ?? 'unknown'}'));
    }
  }

  void _emit(CanvasEditorEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
