// CanvasLayoutController — owns the canvas viewport state that was
// previously scattered across _DesignCanvasPageState. Pure
// ChangeNotifier: no BuildContext, no widget deps, testable in plain
// Dart. Follows ADR-0007 (ChangeNotifier controller pattern).

import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../app/router.dart';
import '../../core/design_system/device_specs.dart';

enum PreviewMode { free, iphone15, pixel7, allDevices }

class CanvasLayoutController extends ChangeNotifier {
  // ── Preview mode ──────────────────────────────────────────────

  PreviewMode _previewMode = PreviewMode.free;
  PreviewMode get previewMode => _previewMode;
  void setPreviewMode(PreviewMode mode) {
    if (_previewMode == mode) return;
    _previewMode = mode;
    notifyListeners();
  }

  // ── Canvas appearance ─────────────────────────────────────────

  bool _showBackgroundDecor = true;
  bool get showBackgroundDecor => _showBackgroundDecor;
  void setShowBackgroundDecor(bool v) {
    if (_showBackgroundDecor == v) return;
    _showBackgroundDecor = v;
    notifyListeners();
  }

  bool _showConnectors = true;
  bool get showConnectors => _showConnectors;
  void setShowConnectors(bool v) {
    if (_showConnectors == v) return;
    _showConnectors = v;
    notifyListeners();
  }

  // ── Right panel (inspector / live editor) ─────────────────────

  bool _isPanelOpen = false;
  bool get isPanelOpen => _isPanelOpen;
  void togglePanel() {
    _isPanelOpen = !_isPanelOpen;
    notifyListeners();
  }

  void openPanel() {
    if (_isPanelOpen) return;
    _isPanelOpen = true;
    notifyListeners();
  }

  double _inspectorWidth = 320.0;
  double get inspectorWidth => _inspectorWidth;

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  void startDragResize() {
    _isDragging = true;
    notifyListeners();
  }

  void updateInspectorWidth(double delta, double maxWidth) {
    _inspectorWidth = (_inspectorWidth - delta).clamp(200.0, maxWidth);
    notifyListeners();
  }

  void endDragResize() {
    _isDragging = false;
    notifyListeners();
  }

  // ── Component selection (Cmd+Click) ───────────────────────────

  String? _selectedComponentId;
  String? get selectedComponentId => _selectedComponentId;

  bool _selectedComponentIsText = false;
  bool get selectedComponentIsText => _selectedComponentIsText;

  Offset? _selectedComponentPosition;
  Offset? get selectedComponentPosition => _selectedComponentPosition;

  void selectComponent(String id, bool isText, Offset position) {
    if (_selectedComponentId == id) {
      clearSelection();
      return;
    }
    _selectedComponentId = id;
    _selectedComponentIsText = isText;
    _selectedComponentPosition = position;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedComponentId == null) return;
    _selectedComponentId = null;
    _selectedComponentIsText = false;
    _selectedComponentPosition = null;
    notifyListeners();
  }

  // ── Device / screen geometry ──────────────────────────────────

  static const double deviceSpacing = 64.0;
  static const double xSpacing = 200.0;

  DeviceSpec? get singleDevice {
    switch (_previewMode) {
      case PreviewMode.free:
        return AppDevices.free;
      case PreviewMode.iphone15:
        return AppDevices.iphone15;
      case PreviewMode.pixel7:
        return AppDevices.pixel7;
      case PreviewMode.allDevices:
        return null;
    }
  }

  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth =
          AppDevices.values.fold<double>(0, (sum, d) => sum + d.width);
      final spacing = deviceSpacing * (AppDevices.values.length - 1);
      return totalWidth + spacing;
    }
    return singleDevice!.width;
  }

  double get screenHeight {
    if (_previewMode == PreviewMode.allDevices) {
      return AppDevices.values.map((d) => d.height).reduce(max);
    }
    return singleDevice!.height;
  }

  // ── Position helpers ──────────────────────────────────────────

  Map<String, Offset> calculatePositions(List<AppRouteDef> allRoutes) {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    final flat = getFlatRoutes(allRoutes);
    for (final key in flat.keys) {
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  static Map<String, AppRouteDef> getFlatRoutes(List<AppRouteDef> routes) {
    final map = <String, AppRouteDef>{};
    for (final route in routes) {
      final key = route.name ?? route.path;
      map[key] = route;
      if (route.children.isNotEmpty) {
        map.addAll(getFlatRoutes(route.children));
      }
    }
    return map;
  }
}
