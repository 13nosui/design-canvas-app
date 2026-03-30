import 'package:flutter/material.dart';

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
    primary: Colors.deepPurple,
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF212529),
  );

  static const darkColors = AppColors(
    primary: Colors.deepPurple,
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    text: Color(0xFFE0E0E0),
  );

  // 未定義の場合のデフォルト（フォールバック）値
  static const defaultColors = lightColors;
}

// BuildContextから簡単に呼び出せるようにするための拡張
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.defaultColors;
}
