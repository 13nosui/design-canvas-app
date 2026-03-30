import 'package:flutter/material.dart';

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
    borderRadius: 8.0,
  );
}

extension AppShapesExtension on BuildContext {
  AppShapes get appShapes => Theme.of(this).extension<AppShapes>() ?? AppShapes.defaultShapes;
}
