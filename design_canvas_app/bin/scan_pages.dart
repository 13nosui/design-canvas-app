import 'dart:io';

void main() async {
  final dir = Directory('lib/ui/page');
  if (!await dir.exists()) {
    print(
        'Directory lib/ui/page does not exist. Make sure you are running from the project root.');
    return;
  }

  print('Scanning dart files in ${dir.path} ...');
  final files = await dir.list(recursive: true).toList();
  final dartFiles =
      files.whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  // StatefulWidgetまたはStatelessWidgetを継承するクラスを見つける正規表現
  final classRegex = RegExp(
      r'class\s+([A-Z][a-zA-Z0-9_]*)\s+extends\s+(?:StatefulWidget|StatelessWidget)');

  final List<Map<String, String>> scannedPages = [];

  for (final file in dartFiles) {
    try {
      final content = await file.readAsString();
      final match = classRegex.firstMatch(content);
      if (match != null) {
        final className = match.group(1)!;
        // プライベートクラス(_から始まるもの)は除外
        if (!className.startsWith('_')) {
          final relativePath = file.path.replaceFirst('lib/', '');
          scannedPages.add({
            'className': className,
            'path': file.path, // e.g. lib/ui/page/common/sidebar.dart
            'importPath': relativePath, // e.g. ui/page/common/sidebar.dart
          });
        }
      }
    } catch (e) {
      print('Failed to read ${file.path}: $e');
    }
  }

  if (scannedPages.isEmpty) {
    print('No widget classes found.');
  }

  // 自動生成コードの書き出し
  final outPath = 'lib/app/scanned_routes.dart';
  final outBuffer = StringBuffer();

  outBuffer.writeln('// ==========================================');
  outBuffer.writeln('// AUTO-GENERATED FILE. DO NOT MODIFY.');
  outBuffer.writeln('// Please run `dart run bin/scan_pages.dart` to update.');
  outBuffer.writeln('// ==========================================');
  outBuffer.writeln();
  outBuffer.writeln('import \'router.dart\';');
  outBuffer.writeln('import \'../core/sandbox/canvas_sandbox.dart\';');
  outBuffer.writeln();

  for (final page in scannedPages) {
    outBuffer.writeln('import \'../${page['importPath']}\';');
  }

  outBuffer.writeln();
  outBuffer.writeln('final List<AppRouteDef> unconfirmedRoutes = [');

  for (final page in scannedPages) {
    final className = page['className']!;
    final slug =
        page['path']!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    outBuffer.writeln('  AppRouteDef(');
    outBuffer.writeln('    \'/unconfirmed/$slug\',');
    outBuffer.writeln('    \'$className\\n(Scanned)\',');
    // 自動的に CanvasSandbox で囲むことで、Providerなどの外部依存がなくてもプレビューできるように配慮
    outBuffer
        .writeln('    (context) => const CanvasSandbox(child: $className()),');
    outBuffer.writeln('    [], [], \'${page['path']}\'');
    outBuffer.writeln('  ),');
  }

  outBuffer.writeln('];');

  await File(outPath).writeAsString(outBuffer.toString());
  print(
      'Successfully generated $outPath with ${scannedPages.length} scanned routes!');
}
