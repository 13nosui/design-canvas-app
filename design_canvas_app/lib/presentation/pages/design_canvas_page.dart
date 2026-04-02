import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../../core/sandbox/inspectable.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/navigation/canvas_link.dart';
import '../../app/router.dart';
import '../../core/utils/file_exporter_stub.dart'
    if (dart.library.io) '../../core/utils/file_exporter_io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/property_field_editor.dart';

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

class _DesignCanvasPageState extends State<DesignCanvasPage>
    with SingleTickerProviderStateMixin {
  PreviewMode _previewMode = PreviewMode.free;
  bool _showBackgroundDecor = true;
  bool _showConnectors = true;

  bool _isPanelOpen = false;
  double _inspectorWidth = 320.0;
  bool _isDragging = false;

  List<dynamic> _inspectedFields = [];
  String? _inspectedFilePath;
  bool _isInspectorLoading = false;

  String? _selectedComponentId;
  bool _selectedComponentIsText = false;
  Offset? _selectedComponentPosition;
  OverlayEntry? _inlineEditorEntry;
  bool _isModifierPressed = false;

  final CanvasLinkRegistry _linkRegistry = CanvasLinkRegistry();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FocusNode _canvasFocusNode = FocusNode();

  final double deviceSpacing = 64.0;

  DeviceSpec? get _singleDevice {
    switch (_previewMode) {
      case PreviewMode.free:
        return AppDevices.free;
      case PreviewMode.iphone15:
        return AppDevices.iphone15;
      case PreviewMode.pixel7:
        return AppDevices.pixel7;
      case PreviewMode.allDevices:
        return null;
    }
  }

  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth = AppDevices.values
          .fold<double>(0, (sum, device) => sum + device.width);
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

  void _onCanvasPointerDown(PointerDownEvent event) {
    // 👇 キャンバスをクリックした瞬間、確実にフォーカスをキャンバスに取り戻す
    if (!_canvasFocusNode.hasFocus) {
      _canvasFocusNode.requestFocus();
    }

    // 💡 変更：手動フラグではなく、OSのキーボード状態を直接取得する
    final isModifierPressed = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (!isModifierPressed) {
      if (_inlineEditorEntry != null) _removeInlineEditor();
      return;
    }

    final hitTestResult = HitTestResult();
    WidgetsBinding.instance.hitTest(hitTestResult, event.position);

    bool hitInspectable = false;

    for (final entry in hitTestResult.path) {
      if (entry.target is RenderMetaData) {
        final metaData = (entry.target as RenderMetaData).metaData;
        if (metaData is InspectableData) {
          hitInspectable = true;
          setState(() {
            if (_selectedComponentId == metaData.id) {
              _selectedComponentId = null;
              _selectedComponentIsText = false;
              _selectedComponentPosition = null;
            } else {
              _selectedComponentId = metaData.id;
              _selectedComponentIsText = metaData.isText;
              final rb = entry.target as RenderBox;
              final transform = rb.getTransformTo(null);
              final bounds =
                  MatrixUtils.transformRect(transform, rb.paintBounds);
              _selectedComponentPosition = bounds.center;
            }
          });
          break;
        }
      }
    }

    if (!hitInspectable) {
      setState(() {
        _selectedComponentId = null;
        _selectedComponentIsText = false;
        _selectedComponentPosition = null;
        if (_inlineEditorEntry != null) _removeInlineEditor();
      });
    }
  }

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
    if (_inlineEditorEntry != null) {
      _inlineEditorEntry!.remove();
      _inlineEditorEntry = null;
    }
    _canvasFocusNode.dispose();
    super.dispose();
  }

  bool _keyHandler(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyT) {
      if (_selectedComponentId != null &&
          _selectedComponentIsText &&
          _inlineEditorEntry == null) {
        _showInlineEditor();
        return true;
      }
    }
    return false;
  }

  void _removeInlineEditor() {
    if (_inlineEditorEntry != null) {
      _inlineEditorEntry!.remove();
      _inlineEditorEntry = null;
      FocusScope.of(context).requestFocus();
    }
  }

  void _showInlineEditor() {
    if (_selectedComponentId == null || _selectedComponentPosition == null)
      return;

    // Fallback: Currently we hardcode the Timeline text, ideally this comes from node backend or AST
    // ASTパース等で本来の文字列を取得するまでのプレースホルダー
    String currentText = 'New Text';

    final entry = OverlayEntry(builder: (context) {
      return Positioned(
          left: _selectedComponentPosition!.dx - 50,
          top: _selectedComponentPosition!.dy - 25,
          child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                    borderRadius: BorderRadius.circular(8)),
                child: TextField(
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                    ),
                    controller: TextEditingController(text: currentText),
                    onSubmitted: (newText) {
                      _updateCodeText(
                          _inspectedFilePath ??
                              'lib/ui/page/feed/feed_page.dart',
                          _selectedComponentId!,
                          newText);
                      _removeInlineEditor();
                    }),
              )));
    });
    Overlay.of(context).insert(entry);
    _inlineEditorEntry = entry;
  }

  Future<void> _updateCodeText(String path, String id, String newText) async {
    try {
      // テキストウィジェット自体は必ずメインの .dart ファイル側に存在するため、パスを補正する
      if (id.startsWith('__Text__') && path.endsWith('.styles.dart')) {
        path = path.replaceFirst('.styles.dart', '.dart');
      }

      debugPrint(
          'Sending text update to: http://localhost:8080/inspector/replace_text | path: $path, id: $id');

      final response = await http.post(
        Uri.parse('http://localhost:8080/inspector/replace_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': path,
          'id': id,
          'text': newText,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Text updated! Please press "r" in terminal for Hot Reload.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        final errorMsg = 'Failed to replace text: ${response.body}';
        debugPrint(errorMsg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${response.body}',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception replacing text: $e');
    }
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

  Future<void> _loadInspector(String dartFilePath) async {
    final stylesPath = dartFilePath.replaceFirst('.dart', '.styles.dart');
    setState(() {
      _isInspectorLoading = true;
      _inspectedFilePath = stylesPath;
      _inspectedFields = [];
      _isPanelOpen = true;
    });

    try {
      final res = await http.get(
          Uri.parse('http://localhost:8080/inspector/parse?path=$stylesPath'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _inspectedFields = data['fields'] ?? [];
          _isInspectorLoading = false;
        });
      } else {
        if (mounted) setState(() => _isInspectorLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isInspectorLoading = false);
    }
  }

  Future<void> _updateStyleField(
      String? className, String name, String newValue) async {
    if (_inspectedFilePath == null) return;
    try {
      await http.post(
        Uri.parse('http://localhost:8080/inspector/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': _inspectedFilePath,
          'className': className,
          'name': name,
          'value': newValue,
        }),
      );
      // 再パースして最新状態に反映
      await _loadInspector(
          _inspectedFilePath!.replaceFirst('.styles.dart', '.dart'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✨ Style saved! Please press "R" (Shift+r) in terminal for Hot Restart.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _promoteToken(
      String? className, String name, String? tokenName, String value) async {
    if (_inspectedFilePath == null || tokenName == null) return;
    try {
      await http.post(
        Uri.parse('http://localhost:8080/inspector/promote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': _inspectedFilePath,
          'className': className,
          'name': name,
          'tokenName': tokenName,
          'value': value,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✨ Elevated to AppTokens!')));
      }
      await _loadInspector(
          _inspectedFilePath!.replaceFirst('.styles.dart', '.dart'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Promote failed: $e')));
      }
    }
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
    final viewportHeight =
        screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;

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
    String colorToHex(Color c) =>
        '0xFF${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
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
    final c =
        '0x${borderColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

    return '''import 'package:flutter/material.dart';

class AppBorders extends ThemeExtension<AppBorders> {
  final double borderWidth;
  final Color borderColor;

  const AppBorders({
    required this.borderWidth,
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

  String _generateAppGradientsCode(
      bool useGradient, Color startColor, Color endColor) {
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

  String _generateAppTypographyCode(String fontFamily, double baseSize,
      double scaleRatio, int fontWeight, double letterSpacing) {
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

  void _exportAndSaveCode(
      BuildContext context, ThemeControllerProvider themeController) {
    final colorsCode = _generateAppColorsCode(themeController);
    final spacingCode = _generateAppSpacingCode(themeController.spacingBase);
    final shapesCode = _generateAppShapesCode(themeController.borderRadius);
    final elevationsCode =
        _generateAppElevationsCode(themeController.elevation);
    final bordersCode = _generateAppBordersCode(
        themeController.borderWidth, themeController.borderColor);
    final opacityCode = _generateAppOpacityCode(themeController.opacity);
    final blurCode = _generateAppBlurCode(themeController.blur);
    final gradientsCode = _generateAppGradientsCode(themeController.useGradient,
        themeController.gradientStartColor, themeController.gradientEndColor);
    final typographyCode = _generateAppTypographyCode(
      themeController.fontFamily,
      themeController.baseFontSize,
      themeController.scaleRatio,
      themeController.fontWeight,
      themeController.letterSpacing,
    );

    if (kIsWeb) {
      // Webブラウザの場合はローカルファイルへの書き込み権限がないため、クリップボードへ保存
      final fullCode =
          '/* lib/core/design_system/app_colors.dart */\\n\\n\$colorsCode\\n\\n/* lib/core/design_system/app_spacing.dart */\\n\\n\$spacingCode\\n\\n/* lib/core/design_system/app_shapes.dart */\\n\\n\$shapesCode\\n\\n/* lib/core/design_system/app_elevations.dart */\\n\\n\$elevationsCode\\n\\n/* lib/core/design_system/app_borders.dart */\\n\\n\$bordersCode\\n\\n/* lib/core/design_system/app_opacity.dart */\\n\\n\$opacityCode\\n\\n/* lib/core/design_system/app_blur.dart */\\n\\n\$blurCode\\n\\n/* lib/core/design_system/app_gradients.dart */\\n\\n\$gradientsCode\\n\\n/* lib/core/design_system/app_typography.dart */\\n\\n\$typographyCode';
      Clipboard.setData(ClipboardData(text: fullCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Code copied to clipboard (Web Mode)')),
      );
    } else {
      // macOSなどのネイティブ環境ではプロジェクトファイルを直接上書きする
      try {
        saveFilesToDisk(
            colorsCode: colorsCode,
            spacingCode: spacingCode,
            typographyCode: typographyCode,
            shapesCode: shapesCode,
            elevationsCode: elevationsCode,
            bordersCode: bordersCode,
            opacityCode: opacityCode,
            blurCode: blurCode,
            gradientsCode: gradientsCode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🔥 Source files updated directly! (Native Mode)')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving files: \$e')),
        );
      }
    }
  }

  Widget _buildDevicePreview(
      DeviceSpec device, AppRouteDef? route, Widget content) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (route != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🏷️ ${route.path} (${route.name ?? route.path})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (route.filePath != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Inspect Styles',
                    child: IconButton(
                      icon: const Text('🎨', style: TextStyle(fontSize: 16)),
                      onPressed: () => _loadInspector(route.filePath!),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Open in IDE',
                    child: IconButton(
                      icon: const Text('💻', style: TextStyle(fontSize: 16)),
                      onPressed: () async {
                        try {
                          await http.post(
                            Uri.parse('http://localhost:8080/open-ide'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'filePath': route.filePath}),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ IDEを開けません: $e')),
                            );
                          }
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ],
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
                (device.borderRadius - device.bezelWidth)
                    .clamp(0.0, double.infinity),
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

  // 右側に引き出される「ライブ・スタイル・エディタ」の構築（Figmaライクな固定パネル）
  Widget _buildLiveEditorPanel(BuildContext context) {
    final themeController = ThemeControllerProvider.of(context);
    final paletteColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
      Colors.grey,
    ];

    return Container(
      color: Theme.of(context).colorScheme.surface, // Figma-like background
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_inspectedFilePath != null)
                _buildPropertyInspectorPanel(context),
              if (_inspectedFilePath != null) const Divider(thickness: 4),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Live Style Editor',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🚨 Visual Lint Mode',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Switch(
                      value: themeController.isLintMode,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        themeController.updateTheme(isLintMode: val);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Show Background Decor',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🎭 UI State',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    SegmentedButton<MockUIState>(
                      segments: const [
                        ButtonSegment(
                            value: MockUIState.normal,
                            label:
                                Text('Normal', style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.loading,
                            label: Text('Loading',
                                style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.empty,
                            label:
                                Text('Empty', style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.error,
                            label:
                                Text('Error', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {themeController.currentMockState},
                      onSelectionChanged: (Set<MockUIState> newSelection) {
                        themeController.updateTheme(
                            mockState: newSelection.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              // ==========================================
              // 高密度な Figmaライク・インスペクター
              // ==========================================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: const Text('GLOBAL APP TOKENS',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2)),
              ),

              // --- Colors ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PropertyFieldEditor(
                      label: 'Primary Color',
                      initialValue:
                          'Color(0x${themeController.primaryColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()})',
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'Color\(0x([a-fA-F0-9]{8})\)')
                            .firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              primary:
                                  Color(int.parse(match.group(1)!, radix: 16)));
                      },
                    ),
                    const SizedBox(height: 6),
                    // Tiny document colors
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: paletteColors.map((color) {
                        final isSelected =
                            themeController.primaryColor.value == color.value;
                        return GestureDetector(
                          onTap: () =>
                              themeController.updateTheme(primary: color),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.black12,
                                  width: isSelected ? 2 : 1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Layout & Spacing ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Spacing Base',
                      initialValue:
                          themeController.spacingBase.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              spacing: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Radius',
                      initialValue:
                          themeController.borderRadius.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              radius: double.tryParse(match.group(1)!));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Effects & Borders ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Elevation',
                      initialValue:
                          themeController.elevation.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              elevation: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Width',
                      initialValue:
                          themeController.borderWidth.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              borderWidth: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Color',
                      initialValue:
                          'Color(0x${themeController.borderColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()})',
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'Color\(0x([a-fA-F0-9]{8})\)')
                            .firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              borderColor:
                                  Color(int.parse(match.group(1)!, radix: 16)));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Filters ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Opacity',
                      initialValue: themeController.opacity.toStringAsFixed(2),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              opacity: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Backdrop Blur',
                      initialValue: themeController.blur.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              blur: double.tryParse(match.group(1)!));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Typography ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: const Text('TYPOGRAPHY',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 4,
                          child: Text('Font Family',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: themeController.fontFamily,
                                iconSize: 16,
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                items: [
                                  if (themeController.fontFamily == 'Ahem')
                                    const DropdownMenuItem(
                                        value: 'Ahem',
                                        child: Text('Ahem (Test)')),
                                  const DropdownMenuItem(
                                      value: 'Noto Sans JP',
                                      child: Text('Noto Sans (Default)')),
                                  const DropdownMenuItem(
                                      value: 'Roboto', child: Text('Roboto')),
                                  const DropdownMenuItem(
                                      value: 'Montserrat',
                                      child: Text('Montserrat')),
                                  const DropdownMenuItem(
                                      value: 'Playfair Display',
                                      child: Text('Playfair')),
                                  const DropdownMenuItem(
                                      value: 'Lora', child: Text('Lora')),
                                  const DropdownMenuItem(
                                      value: 'Oswald', child: Text('Oswald')),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    themeController.updateTheme(font: val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Base Size',
                      initialValue:
                          themeController.baseFontSize.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              fontSize: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Scale Ratio',
                      initialValue:
                          themeController.scaleRatio.toStringAsFixed(2),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              ratio: double.tryParse(match.group(1)!));
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Font Weight',
                      initialValue: themeController.fontWeight
                          .toDouble()
                          .toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              weight:
                                  double.tryParse(match.group(1)!)?.toInt());
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Letter Spacing',
                      initialValue:
                          themeController.letterSpacing.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        // Letter spacing can be negative, so allow leading -
                        final match = RegExp(r'(-?\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(-?\d+)').firstMatch(v);
                        if (match != null)
                          themeController.updateTheme(
                              letterSpace: double.tryParse(match.group(1)!));
                      },
                    ),
                  ],
                ),
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
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showCommitDialog(context, themeController),
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Commit & Push Design'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: themeController.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCommitDialog(
      BuildContext context, ThemeControllerProvider themeController) async {
    final hexColor =
        '#${themeController.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    final initialMessage =
        'style: UIデザインの更新 (Color: $hexColor, Radius: ${themeController.borderRadius.toStringAsFixed(1)}px)';
    final controller = TextEditingController(text: initialMessage);
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('🚀 Auto-Commit Design'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    '現在のデザイン変更をローカルGitサーバー経由でコミット＆プッシュします。\\nコミットメッセージを編集してください：'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Commit Message',
                  ),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Pushing to GitHub...'),
                ],
              ],
            ),
            actions: [
              if (!isSubmitting)
                TextButton(
                  onPressed: () => Navigator.of(diagContext).pop(),
                  child: const Text('Cancel'),
                ),
              if (!isSubmitting)
                FilledButton(
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    setState(() {
                      isSubmitting = true;
                    });

                    try {
                      final uri = Uri.parse('http://localhost:8080/commit');
                      final response = await http.post(
                        uri,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'message': controller.text}),
                      );

                      if (!mounted) return;
                      Navigator.of(diagContext).pop();

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('✅ Successfully Pushed to GitHub!')),
                        );
                      } else {
                        final err = jsonDecode(response.body)['error'];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('❌ Error: $err'),
                              backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.of(diagContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '❌ サーバーに接続できません (local_git_server.dart を起動していますか？)\\n$e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Confirm & Push'),
                ),
            ],
          );
        });
      },
    );
  }

  Widget _buildPropertyInspectorPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨ Component Inspector',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Target: ${_inspectedFilePath!.split('/').last}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
            ],
          ),
        ),
        if (_isInspectorLoading)
          const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator())),
        if (!_isInspectorLoading)
          ...(() {
            final filteredFields = _inspectedFields.where((f) {
              if (_selectedComponentId == null) return true;
              return f['className'] == _selectedComponentId;
            }).toList();

            if (filteredFields.isEmpty) {
              return [
                const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No styling tokens found in this component.'))
              ];
            }

            return filteredFields.map((field) {
              final className = field['className'];
              final isAppToken = field['isAppToken'] == true;
              final isCandidate = field['isCandidate'] == true;
              final name = field['name'];
              final valueStr = field['value'];
              final candidateName = field['candidateName'];

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.withOpacity(0.1)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedComponentId == null && className != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(className,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold)),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: PropertyFieldEditor(
                            label: name,
                            initialValue: valueStr,
                            isAppToken: isAppToken,
                            onSubmit: (newVal) =>
                                _updateStyleField(className, name, newVal),
                          ),
                        ),
                        if (isAppToken)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.link,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                      ],
                    ),
                    if (isCandidate) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upgrade, size: 12),
                          label: Text('Promote to $candidateName',
                              style: const TextStyle(fontSize: 10)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _promoteToken(
                              className, name, candidateName, valueStr),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList();
          })(),
      ],
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
    final complement = HSLColor.fromColor(primary)
        .withHue((HSLColor.fromColor(primary).hue + 180) % 360)
        .toColor();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Design Canvas'),
        elevation: 1,
        actions: [
          Builder(builder: (context) {
            final themeController = ThemeControllerProvider.of(context);
            return IconButton(
              icon: Icon(themeController.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                themeController.updateTheme(
                    mode: themeController.themeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light);
              },
            );
          }),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(
                    value: PreviewMode.free,
                    label: Text('Free', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.iphone15,
                    label: Text('iPhone 15', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.pixel7,
                    label: Text('Pixel 7', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.allDevices,
                    label: Text('All Devices',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold))),
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
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Toggle Properties Panel',
              onPressed: () {
                setState(() {
                  _isPanelOpen = !_isPanelOpen;
                });
              },
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: _canvasFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.keyT) {
                  if (_selectedComponentId != null &&
                      _selectedComponentIsText &&
                      _inlineEditorEntry == null) {
                    _showInlineEditor();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Listener(
                onPointerDown: _onCanvasPointerDown,
                behavior: HitTestBehavior.translucent,
                child: CanvasState(
                  selectedComponentId: _selectedComponentId,
                  child: InteractiveViewer(
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
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            if (_showBackgroundDecor)
                              Positioned.fill(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: -200,
                                      top: 100,
                                      child: _buildDecorCircle(
                                          primary.withOpacity(0.4), 1200),
                                    ),
                                    Positioned(
                                      left: 1000,
                                      top: -400,
                                      child: _buildDecorCircle(
                                          complement.withOpacity(0.3), 1400),
                                    ),
                                    Positioned(
                                      left: 2800,
                                      top: 500,
                                      child: _buildDecorCircle(
                                          Colors.pinkAccent.withOpacity(0.3),
                                          1000),
                                    ),
                                    Positioned(
                                      left: 4200,
                                      top: -100,
                                      child: _buildDecorCircle(
                                          Colors.cyanAccent.withOpacity(0.3),
                                          1500),
                                    ),
                                    Positioned(
                                      left: 6000,
                                      top: 600,
                                      child: _buildDecorCircle(
                                          primary.withOpacity(0.35), 1100),
                                    ),
                                  ],
                                ),
                              ),
                            if (_showConnectors)
                              Positioned.fill(
                                child: Builder(builder: (context) {
                                  final sitemapDefinition =
                                      <String, List<String>>{};
                                  final flatRoutes =
                                      _getFlatRoutes(canvasRoutes);
                                  for (final r in flatRoutes.values) {
                                    final targets = <String>[];
                                    targets.addAll(r.children
                                        .map((c) => c.name ?? c.path));
                                    // linksToの中に含まれるpathやnameを探索して正しいキー(name ?? path)を取得する
                                    for (final link in r.linksTo) {
                                      final match = flatRoutes.values
                                          .where((def) =>
                                              def.path == link ||
                                              def.name == link)
                                          .firstOrNull;
                                      if (match != null) {
                                        targets.add(match.name ?? match.path);
                                      } else {
                                        targets.add(link);
                                      }
                                    }
                                    sitemapDefinition[r.name ?? r.path] =
                                        targets;
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
                                }),
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
                                    final snakeCaseKey =
                                        entry.key.toLowerCase();
                                    final filePath =
                                        'lib/presentation/pages/${snakeCaseKey}_page.dart';
                                    debugPrint(
                                        'ANTIGRAVITY_OPEN_FILE: $filePath');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '🖥️ Click-to-Code ($filePath)'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _previewMode == PreviewMode.allDevices
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: AppDevices.values
                                              .asMap()
                                              .entries
                                              .map((devEntry) {
                                            final idx = devEntry.key;
                                            final dev = devEntry.value;
                                            final flatRoutes =
                                                _getFlatRoutes(canvasRoutes);
                                            final route = flatRoutes[entry.key];
                                            final content =
                                                CurrentRouteProvider(
                                              routePath: route?.name ??
                                                  route?.path ??
                                                  '',
                                              child: route?.builder(context) ??
                                                  const Center(
                                                      child: Text('Not Found')),
                                            );

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                right: idx <
                                                        AppDevices
                                                                .values.length -
                                                            1
                                                    ? deviceSpacing
                                                    : 0,
                                              ),
                                              child: _buildDevicePreview(
                                                  dev, route, content),
                                            );
                                          }).toList(),
                                        )
                                      : (() {
                                          final flatRoutes =
                                              _getFlatRoutes(canvasRoutes);
                                          final route = flatRoutes[entry.key];
                                          final content = CurrentRouteProvider(
                                            routePath: route?.name ??
                                                route?.path ??
                                                '',
                                            child: route?.builder(context) ??
                                                const Center(
                                                    child: Text('Not Found')),
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
                ),
              ),
            ),
          ), // end Expanded

          // --- Resize Handle (Figma Like) ---
          if (_isPanelOpen)
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) {
                  setState(() => _isDragging = true);
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _inspectorWidth -= details.delta.dx;
                    final maxWidth = MediaQuery.of(context).size.width / 2;
                    _inspectorWidth = _inspectorWidth.clamp(200.0, maxWidth);
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                child: Container(
                  width: 4,
                  color: Colors.transparent,
                ),
              ),
            ),

          // --- Properties Panel ---
          AnimatedContainer(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isPanelOpen ? _inspectorWidth : 0.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color:
                      Colors.grey.withOpacity(0.2), // Figma-like subtle border
                  width: 1,
                ),
              ),
              boxShadow: [
                if (_isPanelOpen)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  )
              ],
            ),
            child: ClipRect(
              // 横幅が0になっても中身がはみ出さないようにClip
              // --- ここから修正 ---
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: _inspectorWidth,
                maxWidth: _inspectorWidth,
                child: Theme(
                  data: ThemeData(
                    useMaterial3: true,
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.blueGrey,
                        brightness: Brightness.light),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(fontSize: 14),
                      bodyMedium: TextStyle(fontSize: 13),
                      bodySmall: TextStyle(fontSize: 11),
                      labelLarge:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  child: Builder(
                    builder: (editorContext) =>
                        _buildLiveEditorPanel(editorContext),
                  ),
                ),
              ),
              // --- ここまで修正 ---
            ),
          ),
        ], // end Row children
      ), // end Row
    ); // end Scaffold
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
          start.dx + 50,
          start.dy,
          end.dx - 50,
          end.dy,
          end.dx,
          end.dy,
        );
      } else {
        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          start.dx - 50,
          start.dy,
          end.dx - 50,
          end.dy,
          end.dx,
          end.dy,
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

      final startPoint =
          Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

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
