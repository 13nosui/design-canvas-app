// ImportPage bottom-sheet flow: FAB → generate pages → tabbed preview +
// code viewer with clipboard / desktop file-write actions.
//
// Split out of `import_page.dart` for file-size discipline. All widgets
// in this file are cooperating internals of a single UX flow — they
// share the in-memory payload and are not meant to be reused elsewhere.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/codegen/page_codegen.dart';
import '../../core/design_system/codegen/page_preview.dart';
import '../../core/utils/page_file_exporter_stub.dart'
    if (dart.library.io) '../../core/utils/page_file_exporter_io.dart';
import '../providers/canvas_virtual_pages.dart';
import '../providers/project_list_controller.dart';
import 'import_page.styles.dart';

/// FAB shown on ImportPage when a payload is loaded. On tap it calls the
/// page generator against the current payload and opens a bottom sheet
/// with live preview + code tabs. `payload` is read at tap-time so the
/// latest edited state is always reflected.
class ImportActionButton extends StatelessWidget {
  const ImportActionButton({super.key, required this.payload});
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: ImportPageStyles.importButtonColor,
      foregroundColor: ImportPageStyles.importButtonForeground,
      icon: const Icon(Icons.code, size: 18),
      label: const Text('キャンバスに取り込む'),
      onPressed: () {
        final pages = generatePagesFromPayload(payload);
        if (pages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('screens が空なので生成するものがありません'),
            ),
          );
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: ImportPageStyles.importSheetBackground,
          builder: (ctx) => _GeneratedPagesSheet(pages: pages, payload: payload),
        );
      },
    );
  }
}

class _GeneratedPagesSheet extends StatelessWidget {
  const _GeneratedPagesSheet({required this.pages, required this.payload});
  final List<GeneratedPage> pages;
  final Map<String, dynamic> payload;

  String get _projectTitle => (payload['title'] as String?) ?? '';
  String get _icon => (payload['icon'] as String?) ?? '';
  List<Map<String, dynamic>> get _meta => _asMaps(payload['meta']);
  List<Map<String, dynamic>> get _apis {
    final detail = payload['detail'];
    if (detail is! Map) return const [];
    return _asMaps(detail['apis']);
  }

  List<String> get _stack {
    final detail = payload['detail'];
    if (detail is! Map) return const [];
    final list = detail['stack'];
    if (list is! List) return const [];
    return list.whereType<String>().toList(growable: false);
  }

  static List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  String get _combinedSource {
    final buffer = StringBuffer();
    for (final p in pages) {
      buffer
        ..writeln('/* === lib/${p.dart.path} === */')
        ..writeln(p.dart.content)
        ..writeln('/* === lib/${p.styles.path} === */')
        ..writeln(p.styles.content);
    }
    return buffer.toString();
  }

  Future<void> _writeToDisk(BuildContext ctx) async {
    try {
      final result = await savePagesToDisk(pages);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${result.writtenPaths.length} 個のファイルを書き出しました。'
            'scanned_routes を再生成してください: '
            'dart scripts/generate_sitemap_widgets.dart',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } on UnsupportedError catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('⚠️ ${e.message}')),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('❌ 書き出しに失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pages.length} ページ / ${pages.length * 2} ファイル を生成',
                      style: ImportPageStyles.itemTitleStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.dashboard_customize, size: 16),
                    label: const Text('キャンバスに送る'),
                    onPressed: () {
                      final vp = context.read<CanvasVirtualPages>();
                      final count = vp.addFromPayload(payload);
                      // Register in project list for the project bar
                      context.read<ProjectListController>()
                          .createFromPayload(payload);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$count 画面をキャンバスに送りました — '
                            'Design Canvas で確認できます',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  if (!kIsWeb)
                    TextButton.icon(
                      icon: const Icon(Icons.save_alt, size: 16),
                      label: const Text('ファイルに書き出す'),
                      onPressed: () => _writeToDisk(context),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: const Text('全てコピー'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _combinedSource),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('クリップボードにコピーしました'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.phone_iphone, size: 18), text: 'プレビュー'),
                Tab(icon: Icon(Icons.code, size: 18), text: 'コード'),
              ],
              labelColor: Color(0xFF0F172A),
              unselectedLabelColor: Color(0xFF94A3B8),
              indicatorColor: Color(0xFF0F172A),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PreviewTab(
                    pages: pages,
                    projectTitle: _projectTitle,
                    icon: _icon,
                    meta: _meta,
                    apis: _apis,
                    stack: _stack,
                  ),
                  _CodeTab(pages: pages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({
    required this.pages,
    required this.projectTitle,
    required this.icon,
    required this.meta,
    required this.apis,
    required this.stack,
  });
  final List<GeneratedPage> pages;
  final String projectTitle;
  final String icon;
  final List<Map<String, dynamic>> meta;
  final List<Map<String, dynamic>> apis;
  final List<String> stack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: pages.length,
        itemBuilder: (ctx, index) {
          final page = pages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Text(
                  '${page.className}Page',
                  style: ImportPageStyles.generatedFileLabelStyle.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: PhoneFrame(
                    child: GeneratedPagePreview(
                      screen: page.sourceScreen,
                      projectTitle: projectTitle,
                      icon: icon,
                      meta: meta,
                      apis: apis,
                      stack: stack,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodeTab extends StatelessWidget {
  const _CodeTab({required this.pages});
  final List<GeneratedPage> pages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pages.length * 2,
      itemBuilder: (ctx, index) {
        final page = pages[index ~/ 2];
        final file = index.isEven ? page.dart : page.styles;
        return _GeneratedFileBlock(file: file);
      },
    );
  }
}

class _GeneratedFileBlock extends StatelessWidget {
  const _GeneratedFileBlock({required this.file});
  final GeneratedFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ImportPageStyles.generatedFileBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'lib/${file.path}',
                    style: ImportPageStyles.generatedFileLabelStyle,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: file.content));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${file.path} をコピーしました'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SelectableText(
              file.content,
              style: ImportPageStyles.generatedFileCodeStyle,
            ),
          ),
        ],
      ),
    );
  }
}
