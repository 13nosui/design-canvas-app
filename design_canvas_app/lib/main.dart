import 'package:flutter/material.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_spacing.dart';
import 'core/design_system/app_typography.dart';
import 'core/design_system/app_shapes.dart';
import 'core/design_system/app_elevations.dart';
import 'core/design_system/theme_controller.dart';
import 'presentation/pages/design_canvas_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _fontFamily = 'Noto Sans JP';
  Color _primaryColor = Colors.deepPurple;
  double _spacingBase = 8.0;
  double _baseFontSize = 16.0;
  double _scaleRatio = 1.25;
  int _fontWeight = 400;
  double _letterSpacing = 0.0;
  double _borderRadius = 8.0;
  double _elevation = 2.0;

  void _updateTheme({
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
  }) {
    setState(() {
      if (mode != null) _themeMode = mode;
      if (font != null) _fontFamily = font;
      if (primary != null) _primaryColor = primary;
      if (spacing != null) _spacingBase = spacing;
      if (fontSize != null) _baseFontSize = fontSize;
      if (ratio != null) _scaleRatio = ratio;
      if (weight != null) _fontWeight = weight;
      if (letterSpace != null) _letterSpacing = letterSpace;
      if (radius != null) _borderRadius = radius;
      if (elevation != null) _elevation = elevation;
    });
  }

  ThemeData _buildTheme(Brightness brightness, AppTypography typo) {
    final isDark = brightness == Brightness.dark;
    final baseColors = isDark ? AppColors.darkColors : AppColors.lightColors;
    final appColors = baseColors.copyWith(primary: _primaryColor);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
      surface: appColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appColors.background,
      canvasColor: appColors.surface,
      sliderTheme: SliderThemeData(
        inactiveTrackColor: appColors.text.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: appColors.text.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: appColors.text.withOpacity(0.3)),
        ),
      ),
      textTheme: typo.textTheme.apply(
        bodyColor: appColors.text,
        displayColor: appColors.text,
      ),
      extensions: <ThemeExtension<dynamic>>[
        appColors,
        AppSpacing(
          s: _spacingBase,
          m: _spacingBase * 2,
          l: _spacingBase * 3,
        ),
        AppShapes(borderRadius: _borderRadius),
        AppElevations(elevation: _elevation),
        typo,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography(
      fontFamily: _fontFamily,
      baseSize: _baseFontSize,
      scaleRatio: _scaleRatio,
      fontWeight: _fontWeight,
      letterSpacing: _letterSpacing,
    );

    return ThemeControllerProvider(
      themeMode: _themeMode,
      fontFamily: _fontFamily,
      primaryColor: _primaryColor,
      spacingBase: _spacingBase,
      baseFontSize: _baseFontSize,
      scaleRatio: _scaleRatio,
      fontWeight: _fontWeight,
      letterSpacing: _letterSpacing,
      borderRadius: _borderRadius,
      elevation: _elevation,
      updateTheme: _updateTheme,
      child: MaterialApp(
        title: 'Design Canvas App',
        themeMode: _themeMode,
        theme: _buildTheme(Brightness.light, typo),
        darkTheme: _buildTheme(Brightness.dark, typo),
        home: const DesignCanvasPage(),
      ),
    );
  }
}
