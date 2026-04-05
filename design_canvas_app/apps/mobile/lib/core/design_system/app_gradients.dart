import 'package:flutter/material.dart';

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
    useGradient: false,
    startColor: Color(0xFF6200EE),
    endColor: Color(0xFF3700B3),
  );
}

extension AppGradientsExtension on BuildContext {
  AppGradients get appGradients =>
      Theme.of(this).extension<AppGradients>() ?? AppGradients.defaultGradients;
}
