import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/navigation/sitemap_definition.dart';
import '../../core/navigation/sitemap_widgets.g.dart';
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

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Map<String, Offset> _calculatePositions() {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    
    for (final key in sitemapDefinition.keys) {
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
    final typographyCode = _generateAppTypographyCode(
      themeController.fontFamily,
      themeController.baseFontSize,
      themeController.scaleRatio,
      themeController.fontWeight,
      themeController.letterSpacing,
    );

    if (kIsWeb) {
      // Webブラウザの場合はローカルファイルへの書き込み権限がないため、クリップボードへ保存
      final fullCode = '/* lib/core/design_system/app_colors.dart */\\n\\n\$colorsCode\\n\\n/* lib/core/design_system/app_spacing.dart */\\n\\n\$spacingCode\\n\\n/* lib/core/design_system/app_typography.dart */\\n\\n\$typographyCode';
      Clipboard.setData(ClipboardData(text: fullCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Code copied to clipboard (Web Mode)')),
      );
    } else {
      // macOSなどのネイティブ環境ではプロジェクトファイルを直接上書きする
      try {
        saveFilesToDisk(colorsCode: colorsCode, spacingCode: spacingCode, typographyCode: typographyCode);
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

  Widget _buildDevicePreview(DeviceSpec device, Widget content) {
    return Container(
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
          child: AbsorbPointer(
            child: content,
          ),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Live Style Editor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

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
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: SitemapPainter(
                    sitemap: sitemapDefinition,
                    positions: positions,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    lineColor: context.appColors.primary,
                  ),
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
                              final content = generatedScreenBuilders[entry.key]?.call(context) ?? const Center(child: Text('Not Found'));
                              
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: idx < AppDevices.values.length - 1 ? deviceSpacing : 0,
                                ),
                                child: _buildDevicePreview(dev, content),
                              );
                            }).toList(),
                          )
                        : _buildDevicePreview(
                            _singleDevice!,
                            generatedScreenBuilders[entry.key]?.call(context) ?? const Center(child: Text('Not Found')),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SitemapPainter extends CustomPainter {
  final Map<String, List<String>> sitemap;
  final Map<String, Offset> positions;
  final double screenWidth;
  final double screenHeight;
  final Color lineColor;

  SitemapPainter({
    required this.sitemap,
    required this.positions,
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

    for (final fromNode in sitemap.keys) {
      final fromPos = positions[fromNode];
      if (fromPos == null) continue;

      final startPoint = Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

      for (final toNode in sitemap[fromNode]!) {
        final toPos = positions[toNode];
        if (toPos == null) continue;

        final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);

        final path = Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..cubicTo(
            startPoint.dx + 50, startPoint.dy,
            endPoint.dx - 50, endPoint.dy,
            endPoint.dx, endPoint.dy,
          );

        canvas.drawPath(path, paint);
        canvas.drawCircle(endPoint, 6.0, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SitemapPainter oldDelegate) {
    return oldDelegate.screenWidth != screenWidth ||
           oldDelegate.screenHeight != screenHeight ||
           oldDelegate.sitemap != sitemap ||
           oldDelegate.positions != positions ||
           oldDelegate.lineColor != lineColor;
  }
}
