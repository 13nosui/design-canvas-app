import 'package:flutter/material.dart';

class ThemeControllerProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final String fontFamily;
  final Color primaryColor;
  final double spacingBase;
  final double baseFontSize;
  final double scaleRatio;
  final int fontWeight;
  final double letterSpacing;
  final double borderRadius;
  final double elevation;
  final double borderWidth;
  final Color borderColor;
  final double opacity;
  final double blur;
  final bool useGradient;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final void Function({
    ThemeMode? mode,
    String? font,
    Color? primary,
    double? spacing,
    double? fontSize,
    double? ratio,
    int? weight,
    double? letterSpace,
    double? radius,
    double? elevation,
    double? borderWidth,
    Color? borderColor,
    double? opacity,
    double? blur,
    bool? useGradient,
    Color? gradientStartColor,
    Color? gradientEndColor,
  }) updateTheme;

  const ThemeControllerProvider({
    super.key,
    required this.themeMode,
    required this.fontFamily,
    required this.primaryColor,
    required this.spacingBase,
    required this.baseFontSize,
    required this.scaleRatio,
    required this.fontWeight,
    required this.letterSpacing,
    required this.borderRadius,
    required this.elevation,
    required this.borderWidth,
    required this.borderColor,
    required this.opacity,
    required this.blur,
    required this.useGradient,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.updateTheme,
    required super.child,
  });

  static ThemeControllerProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeControllerProvider oldWidget) {
    return themeMode != oldWidget.themeMode ||
           fontFamily != oldWidget.fontFamily ||
           primaryColor != oldWidget.primaryColor || 
           spacingBase != oldWidget.spacingBase ||
           baseFontSize != oldWidget.baseFontSize ||
           scaleRatio != oldWidget.scaleRatio ||
           fontWeight != oldWidget.fontWeight ||
           letterSpacing != oldWidget.letterSpacing ||
           borderRadius != oldWidget.borderRadius ||
           elevation != oldWidget.elevation ||
           borderWidth != oldWidget.borderWidth ||
           borderColor != oldWidget.borderColor ||
           opacity != oldWidget.opacity ||
           blur != oldWidget.blur ||
           useGradient != oldWidget.useGradient ||
           gradientStartColor != oldWidget.gradientStartColor ||
           gradientEndColor != oldWidget.gradientEndColor;
  }
}
