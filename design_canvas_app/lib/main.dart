import 'package:flutter/material.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_spacing.dart';
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

  void _updateTheme({Color? primary, double? spacing}) {
    setState(() {
      if (primary != null) _primaryColor = primary;
      if (spacing != null) _spacingBase = spacing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      primaryColor: _primaryColor,
      spacingBase: _spacingBase,
      updateTheme: _updateTheme,
      child: MaterialApp(
        title: 'Design Canvas App',
        theme: ThemeData(
          // Material 3の colorScheme の基調色としても連動させる
          colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
          useMaterial3: true,
          // 独自のThemeExtensionへ動的な値を注入
          extensions: <ThemeExtension<dynamic>>[
            AppColors(primary: _primaryColor),
            AppSpacing(
              s: _spacingBase,
              m: _spacingBase * 2,
              l: _spacingBase * 3, // Base値を基準に各サイズを連動計算
            ),
          ],
        ),
        home: const DesignCanvasPage(),
      ),
    );
  }
}
