import 'package:flutter/material.dart';

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
    opacity: 1.0,
  );
}

extension AppOpacityExtension on BuildContext {
  AppOpacity get appOpacity =>
      Theme.of(this).extension<AppOpacity>() ?? AppOpacity.defaultOpacity;
}
