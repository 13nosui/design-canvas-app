import 'package:flutter/material.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_spacing.dart';
import 'core/design_system/app_typography.dart';
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
  Color _primaryColor = Colors.deepPurple;
  double _spacingBase = 8.0;
  double _baseFontSize = 16.0;
  double _scaleRatio = 1.25;

  void _updateTheme({Color? primary, double? spacing, double? fontSize, double? ratio}) {
    setState(() {
      if (primary != null) _primaryColor = primary;
      if (spacing != null) _spacingBase = spacing;
      if (fontSize != null) _baseFontSize = fontSize;
      if (ratio != null) _scaleRatio = ratio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography(baseSize: _baseFontSize, scaleRatio: _scaleRatio);

    return ThemeControllerProvider(
      primaryColor: _primaryColor,
      spacingBase: _spacingBase,
      baseFontSize: _baseFontSize,
      scaleRatio: _scaleRatio,
      updateTheme: _updateTheme,
      child: MaterialApp(
        title: 'Design Canvas App',
        theme: ThemeData(
          // Material 3の colorScheme の基調色としても連動させる
          colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
          useMaterial3: true,
          // タイポグラフィを一斉適用（H1からBodyまですべて更新される）
          textTheme: typo.textTheme,
          // 独自のThemeExtensionへ動的な値を注入
          extensions: <ThemeExtension<dynamic>>[
            AppColors(primary: _primaryColor),
            AppSpacing(
              s: _spacingBase,
              m: _spacingBase * 2,
              l: _spacingBase * 3, // Base値を基準に各サイズを連動計算
            ),
            typo,
          ],
        ),
        home: const DesignCanvasPage(),
      ),
    );
  }
}
