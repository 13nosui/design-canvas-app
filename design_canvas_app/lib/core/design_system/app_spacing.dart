import 'package:flutter/material.dart';

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

  // 8px単位のデフォルトの余白設定
  static const defaultSpacing = AppSpacing(
    s: 8.0,
    m: 16.0,
    l: 24.0,
  );
}

// BuildContextから簡単に呼び出せるようにするための拡張
extension AppSpacingExtension on BuildContext {
  AppSpacing get appSpacing => Theme.of(this).extension<AppSpacing>() ?? AppSpacing.defaultSpacing;
}
