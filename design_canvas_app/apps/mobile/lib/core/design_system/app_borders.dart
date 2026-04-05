import 'package:flutter/material.dart';

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
    borderWidth: 0.0,
    borderColor: Colors.black,
  );
}

extension AppBordersExtension on BuildContext {
  AppBorders get appBorders =>
      Theme.of(this).extension<AppBorders>() ?? AppBorders.defaultBorders;
}
