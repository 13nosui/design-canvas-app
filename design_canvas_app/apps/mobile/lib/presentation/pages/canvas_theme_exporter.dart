// canvas_theme_exporter — extracts the design-token export action out
// of DesignCanvasPage. On web we can only write to the clipboard; on
// native we write all generated files directly to disk. Kept as a free
// function rather than a class so the widget can call it inline from
// the Live Editor panel.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/codegen/theme_codegen.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/utils/file_exporter_stub.dart'
    if (dart.library.io) '../../core/utils/file_exporter_io.dart';

void exportAndSaveCanvasTheme(
  BuildContext context,
  ThemeControllerProvider themeController,
) {
  final colorsCode = generateAppColorsCode(themeController.primaryColor);
  final spacingCode = generateAppSpacingCode(themeController.spacingBase);
  final shapesCode = generateAppShapesCode(themeController.borderRadius);
  final elevationsCode = generateAppElevationsCode(themeController.elevation);
  final bordersCode = generateAppBordersCode(
      themeController.borderWidth, themeController.borderColor);
  final opacityCode = generateAppOpacityCode(themeController.opacity);
  final blurCode = generateAppBlurCode(themeController.blur);
  final gradientsCode = generateAppGradientsCode(
      themeController.useGradient,
      themeController.gradientStartColor,
      themeController.gradientEndColor);
  final typographyCode = generateAppTypographyCode(
    themeController.fontFamily,
    themeController.baseFontSize,
    themeController.scaleRatio,
    themeController.fontWeight,
    themeController.letterSpacing,
  );

  if (kIsWeb) {
    // Web has no filesystem write access — fall back to clipboard so
    // the user can paste the generated code somewhere else.
    final fullCode =
        '/* lib/core/design_system/app_colors.dart */\\n\\n\$colorsCode\\n\\n/* lib/core/design_system/app_spacing.dart */\\n\\n\$spacingCode\\n\\n/* lib/core/design_system/app_shapes.dart */\\n\\n\$shapesCode\\n\\n/* lib/core/design_system/app_elevations.dart */\\n\\n\$elevationsCode\\n\\n/* lib/core/design_system/app_borders.dart */\\n\\n\$bordersCode\\n\\n/* lib/core/design_system/app_opacity.dart */\\n\\n\$opacityCode\\n\\n/* lib/core/design_system/app_blur.dart */\\n\\n\$blurCode\\n\\n/* lib/core/design_system/app_gradients.dart */\\n\\n\$gradientsCode\\n\\n/* lib/core/design_system/app_typography.dart */\\n\\n\$typographyCode';
    Clipboard.setData(ClipboardData(text: fullCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Code copied to clipboard (Web Mode)')),
    );
    return;
  }

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
      gradientsCode: gradientsCode,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('🔥 Source files updated directly! (Native Mode)')),
    );
  } on Exception catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving files: $e')),
    );
  }
}
