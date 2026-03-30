import 'dart:io';

void saveFilesToDisk({required String colorsCode, required String spacingCode, required String typographyCode}) {
  final colorFile = File('lib/core/design_system/app_colors.dart');
  final spacingFile = File('lib/core/design_system/app_spacing.dart');
  final typographyFile = File('lib/core/design_system/app_typography.dart');

  if (colorFile.existsSync() && spacingFile.existsSync()) {
    colorFile.writeAsStringSync(colorsCode);
    spacingFile.writeAsStringSync(spacingCode);
    
    if (!typographyFile.existsSync()) {
      typographyFile.createSync(recursive: true);
    }
    typographyFile.writeAsStringSync(typographyCode);
  } else {
    throw Exception('Files not found. Ensure you are running from the project root.');
  }
}
