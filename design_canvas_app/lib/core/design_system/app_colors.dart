import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primary;

  const AppColors({
    required this.primary,
  });

  @override
  AppColors copyWith({Color? primary}) {
    return AppColors(
      primary: primary ?? this.primary,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
    );
  }

  // 未定義の場合のデフォルト（フォールバック）値
  static const defaultColors = AppColors(
    primary: Colors.blue,
  );
}

// BuildContextから簡単に呼び出せるようにするための拡張
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.defaultColors;
}
