import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/navigation/canvas_link.dart';
import '../../app/router.dart';
import '../../core/utils/file_exporter_stub.dart' if (dart.library.io) '../../core/utils/file_exporter_io.dart';

enum PreviewMode {
  free,
  iphone15,
  pixel7,
  allDevices,
}

class DesignCanvasPage extends StatefulWidget {
  const DesignCanvasPage({super.key});

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage> with SingleTickerProviderStateMixin {
  PreviewMode _previewMode = PreviewMode.free;
  bool _showBackgroundDecor = true;
  bool _showConnectors = true;

  final CanvasLinkRegistry _linkRegistry = CanvasLinkRegistry();
  final GlobalKey _canvasKey = GlobalKey();

  final double deviceSpacing = 64.0;

  DeviceSpec? get _singleDevice {
    switch (_previewMode) {
      case PreviewMode.free: return AppDevices.free;
      case PreviewMode.iphone15: return AppDevices.iphone15;
      case PreviewMode.pixel7: return AppDevices.pixel7;
      case PreviewMode.allDevices: return null;
    }
  }

  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth = AppDevices.values.fold<double>(0, (sum, device) => sum + device.width);
      final spacingWidth = deviceSpacing * (AppDevices.values.length - 1);
      return totalWidth + spacingWidth;
    }
    return _singleDevice!.width;
  }

  double get screenHeight {
    if (_previewMode == PreviewMode.allDevices) {
      return AppDevices.values.map((d) => d.height).reduce((a, b) => max(a, b));
    }
    return _singleDevice!.height;
  }

  final double xSpacing = 200;

  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _linkRegistry.addListener(_onLinksChanged);
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  void _onLinksChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _linkRegistry.removeListener(_onLinksChanged);
    _linkRegistry.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Map<String, AppRouteDef> _getFlatRoutes(List<AppRouteDef> routes) {
    final Map<String, AppRouteDef> map = {};
    for (var route in routes) {
      final key = route.name ?? route.path;
      map[key] = route;
      if (route.children.isNotEmpty) {
        map.addAll(_getFlatRoutes(route.children));
      }
    }
    return map;
  }

  Map<String, Offset> _calculatePositions() {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    
    final flatRoutes = _getFlatRoutes(canvasRoutes);
    for (final key in flatRoutes.keys) {
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  void _zoomToScreen(Offset targetPosition) {
    final screenSize = MediaQuery.of(context).size;
    
    double targetScale = 1.0;
    if (_previewMode == PreviewMode.allDevices) {
      targetScale = min(1.0, screenSize.width / (screenWidth + 100));
    }

    final screenCenterX = targetPosition.dx + (screenWidth / 2);
    final screenCenterY = targetPosition.dy + (screenHeight / 2);

    final viewportWidth = screenSize.width;
    final viewportHeight = screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;

    final viewportCenterX = viewportWidth / 2;
    final viewportCenterY = viewportHeight / 2;

    final targetX = viewportCenterX - (screenCenterX * targetScale);
    final targetY = viewportCenterY - (screenCenterY * targetScale);

    final targetMatrix = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(targetScale);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    ));

    _animationController.forward(from: 0.0);
  }

  String _generateAppColorsCode(ThemeControllerProvider themeController) {
    String colorToHex(Color c) => '0xFF${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final primary = themeController.primaryColor;

    return '''import 'package:flutter/material.dart';

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
    primary: Color(${colorToHex(primary)}),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF212529),
  );

  static const darkColors = AppColors(
    primary: Color(${colorToHex(primary)}),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    text: Color(0xFFE0E0E0),
  );

  static const defaultColors = lightColors;
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.defaultColors;
}
''';
  }

  String _generateAppSpacingCode(double base) {
    final s = base.toStringAsFixed(1);
    final m = (base * 2).toStringAsFixed(1);
    final l = (base * 3).toStringAsFixed(1);
    
    return '''import 'package:flutter/material.dart';

class AppSpacing extends ThemeExtension<AppSpacing> {
  final double s;
  final double m;
  final double l;

  const AppSpacing({
    required this.s,
    required this.m,
    required this.l,
  });

  @override
  AppSpacing copyWith({
    double? s,
    double? m,
    double? l,
  }) {
    return AppSpacing(
      s: s ?? this.s,
      m: m ?? this.m,
      l: l ?? this.l,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      s: s + (other.s - s) * t,
      m: m + (other.m - m) * t,
      l: l + (other.l - l) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultSpacing = AppSpacing(
    s: $s,
    m: $m,
    l: $l,
  );
}

extension AppSpacingExtension on BuildContext {
  AppSpacing get appSpacing => Theme.of(this).extension<AppSpacing>() ?? AppSpacing.defaultSpacing;
}
''';
  }

  String _generateAppShapesCode(double radius) {
    final r = radius.toStringAsFixed(1);
    
    return '''import 'package:flutter/material.dart';

class AppShapes extends ThemeExtension<AppShapes> {
  final double borderRadius;

  const AppShapes({
    required this.borderRadius,
  });

  @override
  AppShapes copyWith({double? borderRadius}) {
    return AppShapes(
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  AppShapes lerp(ThemeExtension<AppShapes>? other, double t) {
    if (other is! AppShapes) {
      return this;
    }
    return AppShapes(
      borderRadius: borderRadius + (other.borderRadius - borderRadius) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultShapes = AppShapes(
    borderRadius: $r,
  );
}

extension AppShapesExtension on BuildContext {
  AppShapes get appShapes => Theme.of(this).extension<AppShapes>() ?? AppShapes.defaultShapes;
}
''';
  }

  String _generateAppElevationsCode(double elevation) {
    final e = elevation.toStringAsFixed(1);
    
    return '''import 'package:flutter/material.dart';

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
    elevation: $e,
  );
}

extension AppElevationsExtension on BuildContext {
  AppElevations get appElevations => Theme.of(this).extension<AppElevations>() ?? AppElevations.defaultElevations;
}
''';
  }

  String _generateAppBordersCode(double borderWidth, Color borderColor) {
    final w = borderWidth.toStringAsFixed(1);
    final c = '0x${borderColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    
    return '''import 'package:flutter/material.dart';

class AppBorders extends ThemeExtension<AppBorders> {
  final double borderWidth;
  final Color borderColor;

  const AppBorders({
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  AppBorders copyWith({
    double? borderWidth,
    Color? borderColor,
  }) {
    return AppBorders(
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  AppBorders lerp(ThemeExtension<AppBorders>? other, double t) {
    if (other is! AppBorders) {
      return this;
    }
    return AppBorders(
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultBorders = AppBorders(
    borderWidth: $w,
    borderColor: Color($c),
  );
}

extension AppBordersExtension on BuildContext {
  AppBorders get appBorders => Theme.of(this).extension<AppBorders>() ?? AppBorders.defaultBorders;
}
''';
  }

  String _generateAppOpacityCode(double opacity) {
    final o = opacity.toStringAsFixed(2);
    
    return '''import 'package:flutter/material.dart';

class AppOpacity extends ThemeExtension<AppOpacity> {
  final double opacity;

  const AppOpacity({
    required this.opacity,
  });

  @override
  AppOpacity copyWith({double? opacity}) {
    return AppOpacity(
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  AppOpacity lerp(ThemeExtension<AppOpacity>? other, double t) {
    if (other is! AppOpacity) {
      return this;
    }
    return AppOpacity(
      opacity: opacity + (other.opacity - opacity) * t,
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultOpacity = AppOpacity(
    opacity: $o,
  );
}

extension AppOpacityExtension on BuildContext {
  AppOpacity get appOpacity => Theme.of(this).extension<AppOpacity>() ?? AppOpacity.defaultOpacity;
}
''';
  }

  String _generateAppBlurCode(double blur) {
    final b = blur.toStringAsFixed(1);
    
    return '''import 'package:flutter/material.dart';

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
    blur: $b,
  );
}

extension AppBlurExtension on BuildContext {
  AppBlur get appBlur => Theme.of(this).extension<AppBlur>() ?? AppBlur.defaultBlur;
}
''';
  }

  String _generateAppGradientsCode(bool useGradient, Color startColor, Color endColor) {
    String _colorToHex(Color color) {
      return '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }

    final startHex = _colorToHex(startColor);
    final endHex = _colorToHex(endColor);

    return '''import 'package:flutter/material.dart';

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
    useGradient: $useGradient,
    startColor: Color($startHex),
    endColor: Color($endHex),
  );
}

extension AppGradientsExtension on BuildContext {
  AppGradients get appGradients => Theme.of(this).extension<AppGradients>() ?? AppGradients.defaultGradients;
}
''';
  }

  String _generateAppTypographyCode(String fontFamily, double baseSize, double scaleRatio, int fontWeight, double letterSpacing) {
    return '''import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final String fontFamily;
  final double baseSize;
  final double scaleRatio;
  final int fontWeight;
  final double letterSpacing;

  const AppTypography({
    required this.fontFamily,
    required this.baseSize,
    required this.scaleRatio,
    required this.fontWeight,
    required this.letterSpacing,
  });

  @override
  AppTypography copyWith({
    String? fontFamily,
    double? baseSize,
    double? scaleRatio,
    int? fontWeight,
    double? letterSpacing,
  }) {
    return AppTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      baseSize: baseSize ?? this.baseSize,
      scaleRatio: scaleRatio ?? this.scaleRatio,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      baseSize: baseSize + (other.baseSize - baseSize) * t,
      scaleRatio: scaleRatio + (other.scaleRatio - scaleRatio) * t,
      fontWeight: (fontWeight + (other.fontWeight - fontWeight) * t).round(),
      letterSpacing: letterSpacing + (other.letterSpacing - letterSpacing) * t,
    );
  }

  double _pow(int exponent) {
    return math.pow(scaleRatio, exponent).toDouble();
  }

  TextStyle _applyFont(TextStyle style) {
    final dynamicWeight = FontWeight.values.firstWhere(
      (w) => w.value == fontWeight,
      orElse: () => FontWeight.w400,
    );

    final modifiedStyle = style.copyWith(
      fontWeight: dynamicWeight,
      letterSpacing: letterSpacing,
    );

    try {
      return GoogleFonts.getFont(fontFamily, textStyle: modifiedStyle);
    } catch (_) {
      return modifiedStyle.copyWith(fontFamily: fontFamily);
    }
  }

  TextTheme get textTheme {
    return TextTheme(
      displayLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(5))),
      displayMedium: _applyFont(TextStyle(fontSize: baseSize * _pow(4))),
      displaySmall: _applyFont(TextStyle(fontSize: baseSize * _pow(3))),
      headlineLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(3))),
      headlineMedium: _applyFont(TextStyle(fontSize: baseSize * _pow(2))),
      headlineSmall: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      titleLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      titleMedium: _applyFont(TextStyle(fontSize: baseSize)),
      titleSmall: _applyFont(TextStyle(fontSize: baseSize * _pow(-1))),
      bodyLarge: _applyFont(TextStyle(fontSize: baseSize * _pow(1))),
      bodyMedium: _applyFont(TextStyle(fontSize: baseSize)),
      bodySmall: _applyFont(TextStyle(fontSize: baseSize * _pow(-1))),
      labelLarge: _applyFont(TextStyle(fontSize: baseSize * 0.9)),
      labelMedium: _applyFont(TextStyle(fontSize: baseSize * 0.8)),
      labelSmall: _applyFont(TextStyle(fontSize: baseSize * 0.7)),
    );
  }

  // ライブエディタからのエクスポート値
  static const defaultTypography = AppTypography(
    fontFamily: '\$fontFamily',
    baseSize: $baseSize,
    scaleRatio: $scaleRatio,
    fontWeight: $fontWeight,
    letterSpacing: $letterSpacing,
  );
}

extension AppTypographyExtension on BuildContext {
  AppTypography get appTypography => Theme.of(this).extension<AppTypography>() ?? AppTypography.defaultTypography;
}
''';
  }

  void _exportAndSaveCode(BuildContext context, ThemeControllerProvider themeController) {
    final colorsCode = _generateAppColorsCode(themeController);
    final spacingCode = _generateAppSpacingCode(themeController.spacingBase);
    final shapesCode = _generateAppShapesCode(themeController.borderRadius);
    final elevationsCode = _generateAppElevationsCode(themeController.elevation);
    final bordersCode = _generateAppBordersCode(themeController.borderWidth, themeController.borderColor);
    final opacityCode = _generateAppOpacityCode(themeController.opacity);
    final blurCode = _generateAppBlurCode(themeController.blur);
    final gradientsCode = _generateAppGradientsCode(themeController.useGradient, themeController.gradientStartColor, themeController.gradientEndColor);
    final typographyCode = _generateAppTypographyCode(
      themeController.fontFamily,
      themeController.baseFontSize,
      themeController.scaleRatio,
      themeController.fontWeight,
      themeController.letterSpacing,
    );

    if (kIsWeb) {
      // Webブラウザの場合はローカルファイルへの書き込み権限がないため、クリップボードへ保存
      final fullCode = '/* lib/core/design_system/app_colors.dart */\\n\\n\$colorsCode\\n\\n/* lib/core/design_system/app_spacing.dart */\\n\\n\$spacingCode\\n\\n/* lib/core/design_system/app_shapes.dart */\\n\\n\$shapesCode\\n\\n/* lib/core/design_system/app_elevations.dart */\\n\\n\$elevationsCode\\n\\n/* lib/core/design_system/app_borders.dart */\\n\\n\$bordersCode\\n\\n/* lib/core/design_system/app_opacity.dart */\\n\\n\$opacityCode\\n\\n/* lib/core/design_system/app_blur.dart */\\n\\n\$blurCode\\n\\n/* lib/core/design_system/app_gradients.dart */\\n\\n\$gradientsCode\\n\\n/* lib/core/design_system/app_typography.dart */\\n\\n\$typographyCode';
      Clipboard.setData(ClipboardData(text: fullCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Code copied to clipboard (Web Mode)')),
      );
    } else {
      // macOSなどのネイティブ環境ではプロジェクトファイルを直接上書きする
      try {
        saveFilesToDisk(colorsCode: colorsCode, spacingCode: spacingCode, typographyCode: typographyCode, shapesCode: shapesCode, elevationsCode: elevationsCode, bordersCode: bordersCode, opacityCode: opacityCode, blurCode: blurCode, gradientsCode: gradientsCode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔥 Source files updated directly! (Native Mode)')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving files: \$e')),
        );
      }
    }
  }

  Widget _buildDevicePreview(DeviceSpec device, AppRouteDef? route, Widget content) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if (route != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🏷️ ${route.path} (${route.name ?? route.path})',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: device.width,
          height: device.height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(device.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, 15),
              )
            ],
          ),
          padding: EdgeInsets.all(device.bezelWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              (device.borderRadius - device.bezelWidth).clamp(0.0, double.infinity),
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: content,
            ),
          ),
        ),
      ],
    ),
   );
  }

  // 右側に引き出される「ライブ・スタイル・エディタ」の構築
  Widget _buildLiveEditorDrawer(BuildContext context) {
    // ThemeControllerProviderの値を監視して即時再描画
    final themeController = ThemeControllerProvider.of(context);
    
    // Flutter標準の18色のプライマリーカラー一覧
    final List<Color> paletteColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.blueGrey, Colors.grey,
    ];

    return Drawer(
      width: 320,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80.0), // スクロール最下部でのボタンの押しやすさを確保
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Live Style Editor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Show Background Decor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Switch(
                    value: _showBackgroundDecor,
                    onChanged: (val) {
                      setState(() {
                        _showBackgroundDecor = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // --- Color Picker ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Primary Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: paletteColors.map((color) {
                  final isSelected = themeController.primaryColor.value == color.value;
                  return GestureDetector(
                    onTap: () => themeController.updateTheme(primary: color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            
            // --- Spacing Slider ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Spacing Base Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // 現在の値から割り出したSMLの一覧を表示
              child: Text(
                'Current Base: ${themeController.spacingBase.toStringAsFixed(1)}px\n\n'
                '• S (Small): ${themeController.spacingBase.toStringAsFixed(1)}px\n'
                '• M (Medium): ${(themeController.spacingBase * 2).toStringAsFixed(1)}px\n'
                '• L (Large): ${(themeController.spacingBase * 3).toStringAsFixed(1)}px',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.spacingBase,
              min: 4.0,
              max: 24.0,
              divisions: 20,
              label: '${themeController.spacingBase.toStringAsFixed(1)} px',
              onChanged: (val) {
                // スライダーを動かした瞬間にThemeControllerに通知が行き、即座にリビルド連鎖が起きる
                themeController.updateTheme(spacing: val);
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            
            // --- Shapes ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Border Radius', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Current Radius: ${themeController.borderRadius.toStringAsFixed(1)}px',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.borderRadius,
              min: 0.0,
              max: 40.0,
              divisions: 80,
              label: '${themeController.borderRadius.toStringAsFixed(1)} px',
              onChanged: (val) {
                themeController.updateTheme(radius: val);
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            
            // --- Elevations ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Elevation / Shadow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Current Elevation: ${themeController.elevation.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.elevation,
              min: 0.0,
              max: 24.0,
              divisions: 24,
              label: themeController.elevation.toStringAsFixed(1),
              onChanged: (val) {
                themeController.updateTheme(elevation: val);
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            
            // --- Borders ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Border Width', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Current Border: ${themeController.borderWidth.toStringAsFixed(1)}px',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.borderWidth,
              min: 0.0,
              max: 8.0,
              divisions: 16,
              label: '${themeController.borderWidth.toStringAsFixed(1)} px',
              onChanged: (val) {
                themeController.updateTheme(borderWidth: val);
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Border Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Theme.of(context).colorScheme.onSurface, // Text color basically (black/white)
                  ...paletteColors
                ].map((color) {
                  final isSelected = themeController.borderColor.value == color.value;
                  return GestureDetector(
                    onTap: () => themeController.updateTheme(borderColor: color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : Border.all(color: Colors.grey.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),

            // --- Opacity ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Opacity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Current Opacity: ${(themeController.opacity * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.opacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(themeController.opacity * 100).toStringAsFixed(0)} %',
              onChanged: (val) {
                themeController.updateTheme(opacity: val);
              },
            ),
            const SizedBox(height: 32),
            const Divider(),

            // --- Backdrop Blur ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Backdrop Blur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Current Blur: ${themeController.blur.toStringAsFixed(1)}px',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.blur,
              min: 0.0,
              max: 20.0,
              divisions: 40,
              label: '${themeController.blur.toStringAsFixed(1)} px',
              onChanged: (val) {
                themeController.updateTheme(blur: val);
              },
            ),
            const SizedBox(height: 32),
            const Divider(),

            // --- Gradients ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Use Gradient', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Switch(
                    value: themeController.useGradient,
                    onChanged: (val) {
                      themeController.updateTheme(useGradient: val);
                    },
                  ),
                ],
              ),
            ),
            if (themeController.useGradient) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text('Gradient Start Color', style: TextStyle(fontSize: 14)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Colors.black,
                    Colors.white,
                    Colors.grey,
                    ...Colors.primaries,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        themeController.updateTheme(gradientStartColor: color);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeController.gradientStartColor.value == color.value ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text('Gradient End Color', style: TextStyle(fontSize: 14)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Colors.black,
                    Colors.white,
                    Colors.grey,
                    ...Colors.primaries,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        themeController.updateTheme(gradientEndColor: color);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeController.gradientEndColor.value == color.value ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),

            // --- Typography ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Typography', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: DropdownButtonFormField<String>(
                value: themeController.fontFamily,
                decoration: const InputDecoration(
                  labelText: 'Google Font',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Noto Sans JP', child: Text('Noto Sans JP (Default)')),
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(value: 'Montserrat', child: Text('Montserrat')),
                  DropdownMenuItem(value: 'Playfair Display', child: Text('Playfair Display')),
                  DropdownMenuItem(value: 'Lora', child: Text('Lora')),
                  DropdownMenuItem(value: 'Oswald', child: Text('Oswald')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    themeController.updateTheme(font: val);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Base Size (Body): ${themeController.baseFontSize.toStringAsFixed(1)}px\n'
                'Scale Ratio: ${themeController.scaleRatio.toStringAsFixed(3)}x',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87), height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Base Font Size:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            Slider(
              value: themeController.baseFontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              label: '${themeController.baseFontSize.toStringAsFixed(1)} px',
              onChanged: (val) {
                themeController.updateTheme(fontSize: val);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Scale Ratio:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            Slider(
              value: themeController.scaleRatio,
              min: 1.0,
              max: 1.618,
              divisions: 62, // roughly 0.01 increments
              label: '${themeController.scaleRatio.toStringAsFixed(3)}x',
              onChanged: (val) {
                themeController.updateTheme(ratio: val);
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Font Weight:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            Slider(
              value: themeController.fontWeight.toDouble(),
              min: 100.0,
              max: 900.0,
              divisions: 8, // 100, 200, ... 900
              label: 'w${themeController.fontWeight}',
              onChanged: (val) {
                themeController.updateTheme(weight: val.toInt());
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Letter Spacing:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            Slider(
              value: themeController.letterSpacing,
              min: -2.0,
              max: 10.0,
              divisions: 120, // 0.1 increments
              label: '${themeController.letterSpacing.toStringAsFixed(1)}px',
              onChanged: (val) {
                themeController.updateTheme(letterSpace: val);
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Export Code (Save)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeController.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  _exportAndSaveCode(context, themeController);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDecorCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();
    final themeController = ThemeControllerProvider.of(context);
    final primary = themeController.primaryColor;
    final complement = HSLColor.fromColor(primary).withHue((HSLColor.fromColor(primary).hue + 180) % 360).toColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Canvas'),
        elevation: 1,
        actions: [
          Builder(builder: (context) {
            final themeController = ThemeControllerProvider.of(context);
            return IconButton(
              icon: Icon(themeController.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                themeController.updateTheme(mode: themeController.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(value: PreviewMode.free, label: Text('Free', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.iphone15, label: Text('iPhone 15', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.pixel7, label: Text('Pixel 7', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.allDevices, label: Text('All Devices', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
              selected: {_previewMode},
              onSelectionChanged: (Set<PreviewMode> newSelection) {
                setState(() {
                  _previewMode = newSelection.first;
                });
              },
            ),
          ),
          // スライダパネル等を開くボタン
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Live Style Editor',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: _buildLiveEditorDrawer(context), // 右側のサイドパネル
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.05,
        maxScale: 3.0,
        constrained: false,
        child: SizedBox(
          width: 8000,
          height: 3000,
          child: InheritedRegistry(
            registry: _linkRegistry,
            canvasKey: _canvasKey,
            child: Stack(
              key: _canvasKey,
              children: [
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              if (_showBackgroundDecor)
                Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned(
                        left: -200,
                        top: 100,
                        child: _buildDecorCircle(primary.withOpacity(0.4), 1200),
                      ),
                      Positioned(
                        left: 1000,
                        top: -400,
                        child: _buildDecorCircle(complement.withOpacity(0.3), 1400),
                      ),
                      Positioned(
                        left: 2800,
                        top: 500,
                        child: _buildDecorCircle(Colors.pinkAccent.withOpacity(0.3), 1000),
                      ),
                      Positioned(
                        left: 4200,
                        top: -100,
                        child: _buildDecorCircle(Colors.cyanAccent.withOpacity(0.3), 1500),
                      ),
                      Positioned(
                        left: 6000,
                        top: 600,
                        child: _buildDecorCircle(primary.withOpacity(0.35), 1100),
                      ),
                    ],
                  ),
                ),
              if (_showConnectors)
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      final sitemapDefinition = <String, List<String>>{};
                      final flatRoutes = _getFlatRoutes(canvasRoutes);
                      for (final r in flatRoutes.values) {
                        final targets = <String>[];
                        targets.addAll(r.children.map((c) => c.name ?? c.path));
                        // linksToの中に含まれるpathやnameを探索して正しいキー(name ?? path)を取得する
                        for (final link in r.linksTo) {
                          final match = flatRoutes.values.where((def) => def.path == link || def.name == link).firstOrNull;
                          if (match != null) {
                            targets.add(match.name ?? match.path);
                          } else {
                            targets.add(link);
                          }
                        }
                        sitemapDefinition[r.name ?? r.path] = targets;
                      }
                      return CustomPaint(
                        painter: SitemapPainter(
                          sitemap: sitemapDefinition,
                          positions: positions,
                          dynamicLinks: _linkRegistry.links,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          lineColor: context.appColors.primary,
                        ),
                      );
                    }
                  ),
                ),
              for (final entry in positions.entries)
                Positioned(
                  left: entry.value.dx,
                  top: entry.value.dy,
                  width: screenWidth,
                  height: screenHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _zoomToScreen(entry.value),
                    onDoubleTap: () {
                      final snakeCaseKey = entry.key.toLowerCase();
                      final filePath = 'lib/presentation/pages/${snakeCaseKey}_page.dart';
                      debugPrint('ANTIGRAVITY_OPEN_FILE: $filePath');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🖥️ Click-to-Code ($filePath)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: _previewMode == PreviewMode.allDevices
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: AppDevices.values.asMap().entries.map((devEntry) {
                              final idx = devEntry.key;
                              final dev = devEntry.value;
                              final flatRoutes = _getFlatRoutes(canvasRoutes);
                              final route = flatRoutes[entry.key];
                              final content = CurrentRouteProvider(
                                routePath: route?.name ?? route?.path ?? '',
                                child: route?.builder(context) ?? const Center(child: Text('Not Found')),
                              );
                              
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: idx < AppDevices.values.length - 1 ? deviceSpacing : 0,
                                ),
                                child: _buildDevicePreview(dev, route, content),
                              );
                            }).toList(),
                          )
                        : (() {
                            final flatRoutes = _getFlatRoutes(canvasRoutes);
                            final route = flatRoutes[entry.key];
                            final content = CurrentRouteProvider(
                              routePath: route?.name ?? route?.path ?? '',
                              child: route?.builder(context) ?? const Center(child: Text('Not Found')),
                            );
                            return _buildDevicePreview(
                              _singleDevice!,
                              route,
                              content,
                            );
                          })(),
                  ),
                ),
            ],
          ),
         ),
        ),
      ),
    );
  }
}

class SitemapPainter extends CustomPainter {
  final Map<String, List<String>> sitemap;
  final Map<String, Offset> positions;
  final Map<String, CanvasLinkData> dynamicLinks;
  final double screenWidth;
  final double screenHeight;
  final Color lineColor;

  SitemapPainter({
    required this.sitemap,
    required this.positions,
    required this.dynamicLinks,
    required this.screenWidth,
    required this.screenHeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    void drawArrow(Offset start, Offset end, bool fromRight) {
      final path = Path();
      if (fromRight) {
        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          start.dx + 50, start.dy,
          end.dx - 50, end.dy,
          end.dx, end.dy,
        );
      } else {
        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          start.dx - 50, start.dy,
          end.dx - 50, end.dy,
          end.dx, end.dy,
        );
      }

      canvas.drawPath(path, paint);
      
      // Arrowhead
      final headPath = Path()
        ..moveTo(end.dx - 12, end.dy - 6)
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx - 12, end.dy + 6)
        ..close();
      canvas.drawPath(headPath, arrowPaint);
    }

    // Draw static hierarchy & link lines
    for (final fromNode in sitemap.keys) {
      final fromPos = positions[fromNode];
      if (fromPos == null) continue;

      final startPoint = Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

      for (final toNode in sitemap[fromNode]!) {
        final toPos = positions[toNode];
        if (toPos == null) continue;

        final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);
        drawArrow(startPoint, endPoint, true);
      }
    }

    // Draw dynamic CanvasLink lines
    for (final link in dynamicLinks.values) {
      final toPos = positions[link.targetRoute];
      if (toPos == null) continue;

      final startPoint = link.sourceCenter;
      final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);
      // Whether it is coming from right or left
      final fromRight = startPoint.dx < endPoint.dx;
      
      drawArrow(startPoint, endPoint, fromRight);
    }
  }

  @override
  bool shouldRepaint(covariant SitemapPainter oldDelegate) {
    return oldDelegate.screenWidth != screenWidth ||
           oldDelegate.screenHeight != screenHeight ||
           oldDelegate.sitemap != sitemap ||
           oldDelegate.dynamicLinks != dynamicLinks ||
           oldDelegate.positions != positions ||
           oldDelegate.lineColor != lineColor;
  }
}
