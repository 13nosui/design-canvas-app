import 'dart:io';

void saveFilesToDisk({required String colorsCode, required String spacingCode, required String typographyCode, required String shapesCode, required String elevationsCode}) {
  final colorFile = File('lib/core/design_system/app_colors.dart');
  final spacingFile = File('lib/core/design_system/app_spacing.dart');
  final typographyFile = File('lib/core/design_system/app_typography.dart');
  final shapesFile = File('lib/core/design_system/app_shapes.dart');
  final elevationsFile = File('lib/core/design_system/app_elevations.dart');

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
  } else {
    throw Exception('Files not found. Ensure you are running from the project root.');
  }
}
