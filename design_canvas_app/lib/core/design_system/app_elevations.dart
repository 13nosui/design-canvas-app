import 'package:flutter/material.dart';

class AppElevations extends ThemeExtension<AppElevations> {
  final double elevation;

  const AppElevations({
    required this.elevation,
  });

  @override
  AppElevations copyWith({double? elevation}) {
    return AppElevations(
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  AppElevations lerp(ThemeExtension<AppElevations>? other, double t) {
    if (other is! AppElevations) {
      return this;
    }
    return AppElevations(
      elevation: elevation + (other.elevation - elevation) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultElevations = AppElevations(
    elevation: 2.0,
  );
}

extension AppElevationsExtension on BuildContext {
  AppElevations get appElevations =>
      Theme.of(this).extension<AppElevations>() ??
      AppElevations.defaultElevations;
}
