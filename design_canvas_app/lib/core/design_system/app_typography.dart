import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final double baseSize;
  final double scaleRatio;

  const AppTypography({
    required this.baseSize,
    required this.scaleRatio,
  });

  @override
  AppTypography copyWith({
    double? baseSize,
    double? scaleRatio,
  }) {
    return AppTypography(
      baseSize: baseSize ?? this.baseSize,
      scaleRatio: scaleRatio ?? this.scaleRatio,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      baseSize: baseSize + (other.baseSize - baseSize) * t,
      scaleRatio: scaleRatio + (other.scaleRatio - scaleRatio) * t,
    );
  }

  // 階層に基づいたスケール算出
  double _pow(int exponent) {
    return math.pow(scaleRatio, exponent).toDouble();
  }

  // ライブ設定値に基づいた動的なTextThemeの構築
  TextTheme get textTheme {
    return TextTheme(
      displayLarge: TextStyle(fontSize: baseSize * _pow(5), fontWeight: FontWeight.normal),
      displayMedium: TextStyle(fontSize: baseSize * _pow(4), fontWeight: FontWeight.normal),
      displaySmall: TextStyle(fontSize: baseSize * _pow(3), fontWeight: FontWeight.normal),
      headlineLarge: TextStyle(fontSize: baseSize * _pow(3), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: baseSize * _pow(2), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: baseSize * _pow(1), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: baseSize * _pow(1), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: baseSize, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: baseSize * _pow(-1), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: baseSize * _pow(1)),
      bodyMedium: TextStyle(fontSize: baseSize),
      bodySmall: TextStyle(fontSize: baseSize * _pow(-1)),
      labelLarge: TextStyle(fontSize: baseSize * 0.9, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: baseSize * 0.8, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: baseSize * 0.7, fontWeight: FontWeight.w500),
    );
  }

  // 初期デフォルト値（Base 16.0px / Scale 1.25 Major Third）
  static const defaultTypography = AppTypography(
    baseSize: 16.0,
    scaleRatio: 1.25,
  );
}

extension AppTypographyExtension on BuildContext {
  AppTypography get appTypography => Theme.of(this).extension<AppTypography>() ?? AppTypography.defaultTypography;
}
