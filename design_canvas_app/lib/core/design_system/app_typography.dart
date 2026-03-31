import 'dart:math' as math;
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

  // 階層に基づいたスケール算出
  double _pow(int exponent) {
    return math.pow(scaleRatio, exponent).toDouble();
  }

  TextStyle _applyFont(TextStyle style) {
    // スライダーからの整数値（100〜900）をFontWeight列挙型へマッピング
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

  // ライブ設定値に基づいた動的なTextThemeの構築
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

  // 初期デフォルト値（Base 16.0px / Scale 1.25 Major Third）
  static const defaultTypography = AppTypography(
    fontFamily: 'Noto Sans JP',
    baseSize: 16.0,
    scaleRatio: 1.25,
    fontWeight: 400,
    letterSpacing: 0.0,
  );
}

extension AppTypographyExtension on BuildContext {
  AppTypography get appTypography =>
      Theme.of(this).extension<AppTypography>() ??
      AppTypography.defaultTypography;
}
