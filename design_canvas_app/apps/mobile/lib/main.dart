import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_spacing.dart';
import 'core/design_system/app_typography.dart';
import 'core/design_system/app_shapes.dart';
import 'core/design_system/app_elevations.dart';
import 'core/design_system/app_borders.dart';
import 'core/design_system/app_opacity.dart';
import 'core/design_system/app_blur.dart';
import 'core/design_system/app_gradients.dart';
import 'core/design_system/theme_controller.dart';
import 'core/design_system/theme_persistence.dart';
import 'presentation/pages/design_canvas_page.dart';
import 'presentation/pages/import_page.dart';
import 'presentation/providers/canvas_layout_controller.dart';
import 'presentation/providers/canvas_virtual_pages.dart';
import 'presentation/providers/project_list_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final String? initialFontFamily;
  const MyApp({super.key, this.initialFontFamily});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late String _fontFamily;
  Color _primaryColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _fontFamily = widget.initialFontFamily ?? 'Noto Sans JP';
    _restoreTheme();
  }

  void _restoreTheme() {
    final saved = loadThemeState();
    if (saved == null) return;
    _themeMode = saved.themeMode;
    _fontFamily = saved.fontFamily;
    _primaryColor = saved.primaryColor;
    _spacingBase = saved.spacingBase;
    _baseFontSize = saved.baseFontSize;
    _scaleRatio = saved.scaleRatio;
    _fontWeight = saved.fontWeight;
    _letterSpacing = saved.letterSpacing;
    _borderRadius = saved.borderRadius;
    _elevation = saved.elevation;
    _borderWidth = saved.borderWidth;
    _borderColor = saved.borderColor;
    _opacity = saved.opacity;
    _blur = saved.blur;
    _useGradient = saved.useGradient;
    _isLintMode = saved.isLintMode;
    _currentMockState = saved.currentMockState;
    _gradientStartColor = saved.gradientStartColor;
    _gradientEndColor = saved.gradientEndColor;
  }

  double _spacingBase = 8.0;
  double _baseFontSize = 16.0;
  double _scaleRatio = 1.25;
  int _fontWeight = 400;
  double _letterSpacing = 0.0;
  double _borderRadius = 8.0;
  double _elevation = 2.0;
  double _borderWidth = 0.0;
  Color _borderColor = AppColors.lightColors.primary;
  double _opacity = 1.0;
  double _blur = 0.0;
  bool _useGradient = false;
  bool _isLintMode = false;
  MockUIState _currentMockState = MockUIState.normal;
  Color _gradientStartColor = AppColors.lightColors.primary;
  Color _gradientEndColor = const Color(0xFF3700B3);

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
    double? borderWidth,
    Color? borderColor,
    double? opacity,
    double? blur,
    bool? useGradient,
    bool? isLintMode,
    MockUIState? mockState,
    Color? gradientStartColor,
    Color? gradientEndColor,
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
      if (borderWidth != null) _borderWidth = borderWidth;
      if (borderColor != null) _borderColor = borderColor;
      if (opacity != null) _opacity = opacity;
      if (blur != null) _blur = blur;
      if (useGradient != null) _useGradient = useGradient;
      if (isLintMode != null) _isLintMode = isLintMode;
      if (mockState != null) _currentMockState = mockState;
      if (gradientStartColor != null) _gradientStartColor = gradientStartColor;
      if (gradientEndColor != null) _gradientEndColor = gradientEndColor;
    });
    saveThemeState(
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
      borderWidth: _borderWidth,
      borderColor: _borderColor,
      opacity: _opacity,
      blur: _blur,
      useGradient: _useGradient,
      isLintMode: _isLintMode,
      currentMockState: _currentMockState,
      gradientStartColor: _gradientStartColor,
      gradientEndColor: _gradientEndColor,
    );
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
        AppBorders(
          borderWidth: _borderWidth,
          borderColor: _borderColor,
        ),
        AppOpacity(opacity: _opacity),
        AppBlur(blur: _blur),
        AppGradients(
          useGradient: _useGradient,
          startColor: _gradientStartColor,
          endColor: _gradientEndColor,
        ),
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
      borderWidth: _borderWidth,
      borderColor: _borderColor,
      opacity: _opacity,
      blur: _blur,
      useGradient: _useGradient,
      isLintMode: _isLintMode,
      currentMockState: _currentMockState,
      gradientStartColor: _gradientStartColor,
      gradientEndColor: _gradientEndColor,
      updateTheme: _updateTheme,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CanvasVirtualPages()..restoreFromStorage()),
          ChangeNotifierProvider(
              create: (_) => ProjectListController()..restoreFromStorage()),
          ChangeNotifierProvider(create: (_) => CanvasLayoutController()),
        ],
        child: MaterialApp(
          title: 'Design Canvas App',
          themeMode: _themeMode,
          theme: _buildTheme(Brightness.light, typo),
          darkTheme: _buildTheme(Brightness.dark, typo),
          home: const _HomeDispatcher(),
        ),
      ),
    );
  }
}

// URL パスに応じて初期画面を切り替える軽量ディスパッチャ。
// 本格的なルーティング (MaterialApp.router + GoRouter) への移行までの暫定実装。
// - /import  → React 側 prototype_engine からのハンドオフを受ける ImportPage
// - その他   → 既存の DesignCanvasPage
class _HomeDispatcher extends StatelessWidget {
  const _HomeDispatcher();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final path = Uri.base.path;
      if (path == '/import' || path.endsWith('/import/')) {
        return const ImportPage();
      }
    }
    return const DesignCanvasPage();
  }
}
