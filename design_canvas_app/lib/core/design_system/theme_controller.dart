import 'package:flutter/material.dart';

class ThemeControllerProvider extends InheritedWidget {
  final Color primaryColor;
  final double spacingBase;
  final void Function({Color? primary, double? spacing}) updateTheme;

  const ThemeControllerProvider({
    super.key,
    required this.primaryColor,
    required this.spacingBase,
    required this.updateTheme,
    required super.child,
  });

  static ThemeControllerProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeControllerProvider oldWidget) {
    return primaryColor != oldWidget.primaryColor || spacingBase != oldWidget.spacingBase;
  }
}
