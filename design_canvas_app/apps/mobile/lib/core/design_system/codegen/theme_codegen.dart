// ignore_for_file: prefer_interpolation_to_compose_strings
//
// Pure, top-level code generators used by the canvas editor to export
// ThemeExtension source files. Each function takes primitive inputs and
// returns a Dart source string — no Flutter state, no BuildContext.
//
// Extracted from design_canvas_page.dart to establish a reusable pattern
// for generating .dart files from live editor state. The canvas editor
// (and future ImportPage handoff flow) both need "(config) -> dart source"
// functions that are trivial to unit test and keep out of the widget class.

import 'package:flutter/material.dart';

String _colorToHex(Color c) =>
    '0x${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

String _colorToHexFF(Color c) =>
    '0xFF${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

String generateAppColorsCode(Color primary) {
  return '''import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color background;
  final Color surface;
  final Color text;

  const AppColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.text,
  });

  @override
  AppColors copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? text,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      text: Color.lerp(text, other.text, t) ?? text,
    );
  }

  static const lightColors = AppColors(
    primary: Color(${_colorToHexFF(primary)}),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF212529),
  );

  static const darkColors = AppColors(
    primary: Color(${_colorToHexFF(primary)}),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    text: Color(0xFFE0E0E0),
  );

  static const defaultColors = lightColors;
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.defaultColors;
}
''';
}

String generateAppSpacingCode(double base) {
  final s = base.toStringAsFixed(1);
  final m = (base * 2).toStringAsFixed(1);
  final l = (base * 3).toStringAsFixed(1);

  return '''import 'package:flutter/material.dart';

class AppSpacing extends ThemeExtension<AppSpacing> {
  final double s;
  final double m;
  final double l;

  const AppSpacing({
    required this.s,
    required this.m,
    required this.l,
  });

  @override
  AppSpacing copyWith({
    double? s,
    double? m,
    double? l,
  }) {
    return AppSpacing(
      s: s ?? this.s,
      m: m ?? this.m,
      l: l ?? this.l,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      s: s + (other.s - s) * t,
      m: m + (other.m - m) * t,
      l: l + (other.l - l) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultSpacing = AppSpacing(
    s: $s,
    m: $m,
    l: $l,
  );
}

extension AppSpacingExtension on BuildContext {
  AppSpacing get appSpacing => Theme.of(this).extension<AppSpacing>() ?? AppSpacing.defaultSpacing;
}
''';
}

String generateAppShapesCode(double radius) {
  final r = radius.toStringAsFixed(1);

  return '''import 'package:flutter/material.dart';

class AppShapes extends ThemeExtension<AppShapes> {
  final double borderRadius;

  const AppShapes({
    required this.borderRadius,
  });

  @override
  AppShapes copyWith({double? borderRadius}) {
    return AppShapes(
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  AppShapes lerp(ThemeExtension<AppShapes>? other, double t) {
    if (other is! AppShapes) {
      return this;
    }
    return AppShapes(
      borderRadius: borderRadius + (other.borderRadius - borderRadius) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultShapes = AppShapes(
    borderRadius: $r,
  );
}

extension AppShapesExtension on BuildContext {
  AppShapes get appShapes => Theme.of(this).extension<AppShapes>() ?? AppShapes.defaultShapes;
}
''';
}

String generateAppElevationsCode(double elevation) {
  final e = elevation.toStringAsFixed(1);

  return '''import 'package:flutter/material.dart';

class AppElevations extends ThemeExtension<AppElevations> {
  final double elevation;

  const AppElevations({
    required this.elevation,
  });

  @override
  AppElevations copyWith({double? elevation}) {
    return AppElevations(
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  AppElevations lerp(ThemeExtension<AppElevations>? other, double t) {
    if (other is! AppElevations) {
      return this;
    }
    return AppElevations(
      elevation: elevation + (other.elevation - elevation) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultElevations = AppElevations(
    elevation: $e,
  );
}

extension AppElevationsExtension on BuildContext {
  AppElevations get appElevations => Theme.of(this).extension<AppElevations>() ?? AppElevations.defaultElevations;
}
''';
}

String generateAppBordersCode(double borderWidth, Color borderColor) {
  final w = borderWidth.toStringAsFixed(1);
  final c = _colorToHex(borderColor);

  return '''import 'package:flutter/material.dart';

class AppBorders extends ThemeExtension<AppBorders> {
  final double borderWidth;
  final Color borderColor;

  const AppBorders({
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  AppBorders copyWith({
    double? borderWidth,
    Color? borderColor,
  }) {
    return AppBorders(
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  AppBorders lerp(ThemeExtension<AppBorders>? other, double t) {
    if (other is! AppBorders) {
      return this;
    }
    return AppBorders(
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultBorders = AppBorders(
    borderWidth: $w,
    borderColor: Color($c),
  );
}

extension AppBordersExtension on BuildContext {
  AppBorders get appBorders => Theme.of(this).extension<AppBorders>() ?? AppBorders.defaultBorders;
}
''';
}

String generateAppOpacityCode(double opacity) {
  final o = opacity.toStringAsFixed(2);

  return '''import 'package:flutter/material.dart';

class AppOpacity extends ThemeExtension<AppOpacity> {
  final double opacity;

  const AppOpacity({
    required this.opacity,
  });

  @override
  AppOpacity copyWith({double? opacity}) {
    return AppOpacity(
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  AppOpacity lerp(ThemeExtension<AppOpacity>? other, double t) {
    if (other is! AppOpacity) {
      return this;
    }
    return AppOpacity(
      opacity: opacity + (other.opacity - opacity) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultOpacity = AppOpacity(
    opacity: $o,
  );
}

extension AppOpacityExtension on BuildContext {
  AppOpacity get appOpacity => Theme.of(this).extension<AppOpacity>() ?? AppOpacity.defaultOpacity;
}
''';
}

String generateAppBlurCode(double blur) {
  final b = blur.toStringAsFixed(1);

  return '''import 'package:flutter/material.dart';

class AppBlur extends ThemeExtension<AppBlur> {
  final double blur;

  const AppBlur({
    required this.blur,
  });

  @override
  AppBlur copyWith({double? blur}) {
    return AppBlur(
      blur: blur ?? this.blur,
    );
  }

  @override
  AppBlur lerp(ThemeExtension<AppBlur>? other, double t) {
    if (other is! AppBlur) {
      return this;
    }
    return AppBlur(
      blur: blur + (other.blur - blur) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultBlur = AppBlur(
    blur: $b,
  );
}

extension AppBlurExtension on BuildContext {
  AppBlur get appBlur => Theme.of(this).extension<AppBlur>() ?? AppBlur.defaultBlur;
}
''';
}

String generateAppGradientsCode(
    bool useGradient, Color startColor, Color endColor) {
  final startHex = _colorToHex(startColor);
  final endHex = _colorToHex(endColor);

  return '''import 'package:flutter/material.dart';

class AppGradients extends ThemeExtension<AppGradients> {
  final bool useGradient;
  final Color startColor;
  final Color endColor;

  const AppGradients({
    required this.useGradient,
    required this.startColor,
    required this.endColor,
  });

  @override
  AppGradients copyWith({
    bool? useGradient,
    Color? startColor,
    Color? endColor,
  }) {
    return AppGradients(
      useGradient: useGradient ?? this.useGradient,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) {
      return this;
    }
    return AppGradients(
      useGradient: t < 0.5 ? useGradient : other.useGradient,
      startColor: Color.lerp(startColor, other.startColor, t) ?? startColor,
      endColor: Color.lerp(endColor, other.endColor, t) ?? endColor,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultGradients = AppGradients(
    useGradient: $useGradient,
    startColor: Color($startHex),
    endColor: Color($endHex),
  );
}

extension AppGradientsExtension on BuildContext {
  AppGradients get appGradients => Theme.of(this).extension<AppGradients>() ?? AppGradients.defaultGradients;
}
''';
}

String generateAppTypographyCode(String fontFamily, double baseSize,
    double scaleRatio, int fontWeight, double letterSpacing) {
  return '''import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final String fontFamily;
  final double baseSize;
  final double scaleRatio;
  final int fontWeight;
  final double letterSpacing;

  const AppTypography({
    required this.fontFamily,
    required this.baseSize,
    required this.scaleRatio,
    required this.fontWeight,
    required this.letterSpacing,
  });

  @override
  AppTypography copyWith({
    String? fontFamily,
    double? baseSize,
    double? scaleRatio,
    int? fontWeight,
    double? letterSpacing,
  }) {
    return AppTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      baseSize: baseSize ?? this.baseSize,
      scaleRatio: scaleRatio ?? this.scaleRatio,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      baseSize: baseSize + (other.baseSize - baseSize) * t,
      scaleRatio: scaleRatio + (other.scaleRatio - scaleRatio) * t,
      fontWeight: (fontWeight + (other.fontWeight - fontWeight) * t).round(),
      letterSpacing: letterSpacing + (other.letterSpacing - letterSpacing) * t,
    );
  }

  double _pow(int exponent) {
    return math.pow(scaleRatio, exponent).toDouble();
  }

  TextStyle _applyFont(TextStyle style) {
    final dynamicWeight = FontWeight.values.firstWhere(
      (w) => w.value == fontWeight,
      orElse: () => FontWeight.w400,
    );

    final modifiedStyle = style.copyWith(
      fontWeight: dynamicWeight,
      letterSpacing: letterSpacing,
    );

    try {
      return GoogleFonts.getFont(fontFamily, textStyle: modifiedStyle);
    } catch (_) {
      return modifiedStyle.copyWith(fontFamily: fontFamily);
    }
  }

  TextTheme get textTheme {
    return TextTheme(
      displayLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(5))),
      displayMedium: _applyFont(TextStyle(fontSize: baseSize * _pow(4))),
      displaySmall: _applyFont(TextStyle(fontSize: baseSize * _pow(3))),
      headlineLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(3))),
      headlineMedium: _applyFont(TextStyle(fontSize: baseSize * _pow(2))),
      headlineSmall: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      titleLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      titleMedium: _applyFont(TextStyle(fontSize: baseSize)),
      titleSmall: _applyFont(TextStyle(fontSize: baseSize * _pow(-1))),
      bodyLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      bodyMedium: _applyFont(TextStyle(fontSize: baseSize)),
      bodySmall: _applyFont(TextStyle(fontSize: baseSize * _pow(-1))),
      labelLarge: _applyFont(TextStyle(fontSize: baseSize * 0.9)),
      labelMedium: _applyFont(TextStyle(fontSize: baseSize * 0.8)),
      labelSmall: _applyFont(TextStyle(fontSize: baseSize * 0.7)),
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultTypography = AppTypography(
    fontFamily: '\$fontFamily',
    baseSize: $baseSize,
    scaleRatio: $scaleRatio,
    fontWeight: $fontWeight,
    letterSpacing: $letterSpacing,
  );
}

extension AppTypographyExtension on BuildContext {
  AppTypography get appTypography => Theme.of(this).extension<AppTypography>() ?? AppTypography.defaultTypography;
}
''';
}
