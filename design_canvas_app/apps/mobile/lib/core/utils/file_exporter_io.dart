import 'dart:io';

void saveFilesToDisk(
    {required String colorsCode,
    required String spacingCode,
    required String typographyCode,
    required String shapesCode,
    required String elevationsCode,
    required String bordersCode,
    required String opacityCode,
    required String blurCode,
    required String gradientsCode}) {
  final colorFile = File('lib/core/design_system/app_colors.dart');
  final spacingFile = File('lib/core/design_system/app_spacing.dart');
  final typographyFile = File('lib/core/design_system/app_typography.dart');
  final shapesFile = File('lib/core/design_system/app_shapes.dart');
  final elevationsFile = File('lib/core/design_system/app_elevations.dart');
  final bordersFile = File('lib/core/design_system/app_borders.dart');
  final opacityFile = File('lib/core/design_system/app_opacity.dart');
  final blurFile = File('lib/core/design_system/app_blur.dart');
  final gradientsFile = File('lib/core/design_system/app_gradients.dart');

  if (colorFile.existsSync() && spacingFile.existsSync()) {
    colorFile.writeAsStringSync(colorsCode);
    spacingFile.writeAsStringSync(spacingCode);

    if (!typographyFile.existsSync()) {
      typographyFile.createSync(recursive: true);
    }
    typographyFile.writeAsStringSync(typographyCode);

    if (!shapesFile.existsSync()) {
      shapesFile.createSync(recursive: true);
    }
    shapesFile.writeAsStringSync(shapesCode);

    if (!elevationsFile.existsSync()) {
      elevationsFile.createSync(recursive: true);
    }
    elevationsFile.writeAsStringSync(elevationsCode);

    if (!bordersFile.existsSync()) {
      bordersFile.createSync(recursive: true);
    }
    bordersFile.writeAsStringSync(bordersCode);

    if (!opacityFile.existsSync()) {
      opacityFile.createSync(recursive: true);
    }
    opacityFile.writeAsStringSync(opacityCode);

    if (!blurFile.existsSync()) {
      blurFile.createSync(recursive: true);
    }
    blurFile.writeAsStringSync(blurCode);

    if (!gradientsFile.existsSync()) {
      gradientsFile.createSync(recursive: true);
    }
    gradientsFile.writeAsStringSync(gradientsCode);
  } else {
    throw Exception(
        'Files not found. Ensure you are running from the project root.');
  }
}
