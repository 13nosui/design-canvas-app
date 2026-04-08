// Desktop implementation: writes GeneratedPage pairs to `lib/{path}` under
// the current working directory. This assumes the Flutter app is launched
// from `apps/mobile/` (which is how `flutter run -d macos` works from the
// project). If the working directory is wrong, the File.create below will
// land in the wrong place — we intentionally fail loud in that case so the
// user notices.
//
// Paired with `page_file_exporter_stub.dart` via conditional import; see
// `import_page.dart` for the import site.

import 'dart:io';

import '../design_system/codegen/page_codegen.dart';

class PageExportResult {
  final List<String> writtenPaths;
  const PageExportResult(this.writtenPaths);
}

Future<PageExportResult> savePagesToDisk(List<GeneratedPage> pages) async {
  final written = <String>[];
  for (final page in pages) {
    await _writeOne(page.dart.path, page.dart.content);
    written.add('lib/${page.dart.path}');
    await _writeOne(page.styles.path, page.styles.content);
    written.add('lib/${page.styles.path}');
  }
  return PageExportResult(written);
}

Future<void> _writeOne(String relativePath, String content) async {
  final file = File('lib/$relativePath');
  final dir = file.parent;
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  await file.writeAsString(content);
}
