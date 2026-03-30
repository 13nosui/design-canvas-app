import 'package:flutter/material.dart';

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
    blur: 0.0,
  );
}

extension AppBlurExtension on BuildContext {
  AppBlur get appBlur => Theme.of(this).extension<AppBlur>() ?? AppBlur.defaultBlur;
}
