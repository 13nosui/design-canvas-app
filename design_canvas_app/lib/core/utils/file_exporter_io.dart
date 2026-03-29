import 'dart:io';

void saveFilesToDisk({required String colorsCode, required String spacingCode}) {
  final colorFile = File('lib/core/design_system/app_colors.dart');
  final spacingFile = File('lib/core/design_system/app_spacing.dart');

  if (colorFile.existsSync() && spacingFile.existsSync()) {
    colorFile.writeAsStringSync(colorsCode);
    spacingFile.writeAsStringSync(spacingCode);
  } else {
    throw Exception('Files not found. Ensure you are running from the project root.');
  }
}
