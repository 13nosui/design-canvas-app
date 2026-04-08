// Web (or any non-dart:io) platform stub. Throws UnsupportedError because
// writing to the host filesystem is not possible from the browser sandbox.
//
// The dart:io implementation lives in `page_file_exporter_io.dart`.
// Callers must use a conditional import to pick the right one.

import '../design_system/codegen/page_codegen.dart';

class PageExportResult {
  final List<String> writtenPaths;
  const PageExportResult(this.writtenPaths);
}

Future<PageExportResult> savePagesToDisk(List<GeneratedPage> pages) async {
  throw UnsupportedError(
    'Saving pages to disk is not supported on the web platform. '
    'Use the clipboard copy instead.',
  );
}
