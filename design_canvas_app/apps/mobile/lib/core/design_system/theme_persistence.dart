// Theme persistence — serializes / deserializes the design-canvas
// theme slider state to localStorage (web) so that a page reload
// preserves the user's tweaks. On non-web platforms the stub returns
// null and writes are no-ops.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/local_storage_stub.dart'
    if (dart.library.html) '../utils/local_storage_html.dart';
import 'theme_controller.dart';

const _storageKey = 'canvas_theme_state';

/// Persist the current theme slider values.
void saveThemeState({
  required ThemeMode themeMode,
  required String fontFamily,
  required Color primaryColor,
  required double spacingBase,
  required double baseFontSize,
  required double scaleRatio,
  required int fontWeight,
  required double letterSpacing,
  required double borderRadius,
  required double elevation,
  required double borderWidth,
  required Color borderColor,
  required double opacity,
  required double blur,
  required bool useGradient,
  required bool isLintMode,
  required MockUIState currentMockState,
  required Color gradientStartColor,
  required Color gradientEndColor,
}) {
  final data = <String, dynamic>{
    'themeMode': themeMode.index,
    'fontFamily': fontFamily,
    'primaryColor': primaryColor.value,
    'spacingBase': spacingBase,
    'baseFontSize': baseFontSize,
    'scaleRatio': scaleRatio,
    'fontWeight': fontWeight,
    'letterSpacing': letterSpacing,
    'borderRadius': borderRadius,
    'elevation': elevation,
    'borderWidth': borderWidth,
    'borderColor': borderColor.value,
    'opacity': opacity,
    'blur': blur,
    'useGradient': useGradient,
    'isLintMode': isLintMode,
    'currentMockState': currentMockState.index,
    'gradientStartColor': gradientStartColor.value,
    'gradientEndColor': gradientEndColor.value,
  };
  writeLocalStorage(_storageKey, jsonEncode(data));
}

/// Restore the saved theme state, or null if nothing was saved.
/// Each field is individually guarded so partial / corrupted data
/// doesn't crash the app.
SavedThemeState? loadThemeState() {
  final raw = readLocalStorage(_storageKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) return null;
    return SavedThemeState._(data);
  } on FormatException {
    return null;
  }
}

class SavedThemeState {
  SavedThemeState._(this._data);
  final Map<String, dynamic> _data;

  ThemeMode get themeMode {
    final i = _int('themeMode');
    return i != null ? (ThemeMode.values.elementAtOrNull(i) ?? ThemeMode.light) : ThemeMode.light;
  }
  String get fontFamily => _str('fontFamily') ?? 'Noto Sans JP';
  Color get primaryColor => _color('primaryColor') ?? Colors.deepPurple;
  double get spacingBase => _dbl('spacingBase') ?? 8.0;
  double get baseFontSize => _dbl('baseFontSize') ?? 16.0;
  double get scaleRatio => _dbl('scaleRatio') ?? 1.25;
  int get fontWeight => _int('fontWeight') ?? 400;
  double get letterSpacing => _dbl('letterSpacing') ?? 0.0;
  double get borderRadius => _dbl('borderRadius') ?? 8.0;
  double get elevation => _dbl('elevation') ?? 2.0;
  double get borderWidth => _dbl('borderWidth') ?? 0.0;
  Color get borderColor => _color('borderColor') ?? Colors.deepPurple;
  double get opacity => _dbl('opacity') ?? 1.0;
  double get blur => _dbl('blur') ?? 0.0;
  bool get useGradient => _data['useGradient'] == true;
  bool get isLintMode => _data['isLintMode'] == true;
  MockUIState get currentMockState {
    final i = _int('currentMockState');
    return i != null ? (MockUIState.values.elementAtOrNull(i) ?? MockUIState.normal) : MockUIState.normal;
  }
  Color get gradientStartColor =>
      _color('gradientStartColor') ?? Colors.deepPurple;
  Color get gradientEndColor =>
      _color('gradientEndColor') ?? const Color(0xFF3700B3);

  int? _int(String key) {
    final v = _data[key];
    return v is int ? v : null;
  }

  double? _dbl(String key) {
    final v = _data[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return null;
  }

  String? _str(String key) {
    final v = _data[key];
    return v is String ? v : null;
  }

  Color? _color(String key) {
    final v = _int(key);
    return v != null ? Color(v) : null;
  }
}
