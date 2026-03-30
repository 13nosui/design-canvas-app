import 'package:flutter/material.dart';

class ThemeControllerProvider extends InheritedWidget {
  final Color primaryColor;
  final double spacingBase;
  final double baseFontSize;
  final double scaleRatio;
  final void Function({Color? primary, double? spacing, double? fontSize, double? ratio}) updateTheme;

  const ThemeControllerProvider({
    super.key,
    required this.primaryColor,
    required this.spacingBase,
    required this.baseFontSize,
    required this.scaleRatio,
    required this.updateTheme,
    required super.child,
  });

  static ThemeControllerProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeControllerProvider oldWidget) {
    return primaryColor != oldWidget.primaryColor || 
           spacingBase != oldWidget.spacingBase ||
           baseFontSize != oldWidget.baseFontSize ||
           scaleRatio != oldWidget.scaleRatio;
  }
}
