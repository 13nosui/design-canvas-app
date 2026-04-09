// ImportPage — React 側 (prototype_engine) で生成したプロジェクトカードを
// URL クエリ ?data=<base64url(json)> 経由で受け取り、Flutter キャンバスで表示する。
// VISION の "思考の直結" を React → Flutter まで一筆書きで繋ぐ受け側。
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'import_page.styles.dart';
import 'import_page_editors.dart';
import 'import_page_live_preview.dart';
import 'import_page_sheet.dart';
import 'import_payload_controller.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, this.encodedData});

  /// 明示的に data を渡す経路 (テスト用途など)。
  /// null の場合は kIsWeb 環境の Uri.base.queryParameters から自動取得する。
  final String? encodedData;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  late final ImportPayloadController _controller;
  bool _showLivePreview = false;

  @override
  void initState() {
    super.initState();
    final encoded = widget.encodedData ?? _readEncodedFromUrl();
    _controller = ImportPayloadController(_decodePayload(encoded));
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _exportJson() async {
    final jsonStr = _controller.exportAsJson();
    if (jsonStr.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('payload JSON をクリップボードにコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importJson() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ImportJsonDialog(),
    );
    if (result == null || result.isEmpty) return;
    final ok = _controller.importFromJson(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'JSON を読み込みました (Undo で元に戻せます)'
            : '❌ JSON の形式が不正です'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _controller.payload;
    return Scaffold(
      backgroundColor: ImportPageStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            const Text(
              'Imported from Prototype Engine',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_controller.dirty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'edited',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: payload == null
            ? null
            : [
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: _controller.canUndo ? _controller.undo : null,
                ),
                IconButton(
                  tooltip: 'Redo',
                  icon: const Icon(Icons.redo),
                  onPressed: _controller.canRedo ? _controller.redo : null,
                ),
                IconButton(
                  tooltip: _showLivePreview
                      ? 'ライブプレビューを非表示'
                      : 'ライブプレビューを表示',
                  icon: Icon(
                    _showLivePreview
                        ? Icons.visibility
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                      () => _showLivePreview = !_showLivePreview),
                ),
                PopupMenuButton<String>(
                  tooltip: 'その他',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'export') {
                      await _exportJson();
                    } else if (value == 'import') {
                      await _importJson();
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.download, size: 18),
                        title: Text('JSON をコピー'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'import',
                      child: ListTile(
                        leading: Icon(Icons.upload, size: 18),
                        title: Text('JSON から読み込み'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: payload == null
          ? _EmptyState(onStartBlank: _controller.startBlank)
          : Column(
              children: [
                if (_showLivePreview)
                  LivePreviewPanel(payload: payload),
                Expanded(
                  child: _ImportBody(
                    payload: payload,
                    onEdit: _controller.editAtPath,
                    onAddScreen: _controller.addScreen,
                    onRemoveScreen: _controller.removeScreen,
                    onDuplicateScreen: _controller.duplicateScreen,
                    onMoveScreen: _controller.moveScreen,
                    onAddSection: _controller.addSection,
                    onRemoveSection: _controller.removeSection,
                    onAddApi: _controller.addApi,
                    onRemoveApi: _controller.removeApi,
                    onAddStack: _controller.addStack,
                    onRemoveStack: _controller.removeStack,
                    onAddRisk: _controller.addRisk,
                    onRemoveRisk: _controller.removeRisk,
                    onAddMeta: _controller.addMeta,
                    onRemoveMeta: _controller.removeMeta,
                    onCycleMetaColor: _controller.cycleMetaColor,
                  ),
                ),
              ],
            ),
      floatingActionButton: payload == null
          ? null
          : ImportActionButton(payload: payload),
    );
  }
}

String? _readEncodedFromUrl() {
  if (!kIsWeb) return null;
  try {
    return Uri.base.queryParameters['data'];
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _decodePayload(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    // base64url の "=" パディングを補完
    final normalized = base64Url.normalize(encoded);
    final bytes = base64Url.decode(normalized);
    final jsonStr = utf8.decode(bytes);
    final decoded = json.decode(jsonStr);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    return null;
  }
  return null;
}

class _ImportJsonDialog extends StatefulWidget {
  const _ImportJsonDialog();

  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('JSON から読み込み'),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 14,
          minLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '{ "title": "...", "detail": { ... } }',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('読み込む'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartBlank});
  final VoidCallback onStartBlank;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'インポートデータがありません',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'React からハンドオフされた URL にアクセスするか、ゼロから設計を始められます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新規プロジェクトを作成'),
              onPressed: onStartBlank,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportBody extends StatelessWidget {
  const _ImportBody({
    required this.payload,
    required this.onEdit,
    required this.onAddScreen,
    required this.onRemoveScreen,
    required this.onDuplicateScreen,
    required this.onMoveScreen,
    required this.onAddSection,
    required this.onRemoveSection,
    required this.onAddApi,
    required this.onRemoveApi,
    required this.onAddStack,
    required this.onRemoveStack,
    required this.onAddRisk,
    required this.onRemoveRisk,
    required this.onAddMeta,
    required this.onRemoveMeta,
    required this.onCycleMetaColor,
  });
  final Map<String, dynamic> payload;
  final EditAtPath onEdit;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onRemoveScreen;
  final ValueChanged<int> onDuplicateScreen;
  final void Function(int from, int to) onMoveScreen;
  final ValueChanged<int> onAddSection;
  final void Function(int screenIndex, int sectionIndex) onRemoveSection;
  final VoidCallback onAddApi;
  final ValueChanged<int> onRemoveApi;
  final VoidCallback onAddStack;
  final ValueChanged<int> onRemoveStack;
  final VoidCallback onAddRisk;
  final ValueChanged<int> onRemoveRisk;
  final VoidCallback onAddMeta;
  final ValueChanged<int> onRemoveMeta;
  final ValueChanged<int> onCycleMetaColor;

  @override
  Widget build(BuildContext context) {
    final title = (payload['title'] as String?) ?? '名前なし';
    final icon = (payload['icon'] as String?) ?? '✨';
    final summary = (payload['summary'] as String?) ?? '';
    final prompt = (payload['prompt'] as String?) ?? '';
    final meta = _asListOfMaps(payload['meta']);
    final detail = payload['detail'] is Map<String, dynamic>
        ? payload['detail'] as Map<String, dynamic>
        : null;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ImportPageStyles.maxContentWidth),
          child: Padding(
            padding: ImportPageStyles.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(
                  icon: icon,
                  title: title,
                  summary: summary,
                  prompt: prompt,
                  onEdit: onEdit,
                ),
                const SizedBox(height: 16),
                _MetaRow(
                  meta: meta,
                  onEdit: onEdit,
                  onAdd: onAddMeta,
                  onRemove: onRemoveMeta,
                  onCycleColor: onCycleMetaColor,
                ),
                if (detail != null) ..._buildDetailSections(detail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailSections(Map<String, dynamic> detail) {
    final widgets = <Widget>[];
    final screens = _asListOfMaps(detail['screens']);
    final userFlow = (detail['userFlow'] as String?)?.trim();
    final apis = _asListOfMaps(detail['apis']);
    final stack = _asListOfStrings(detail['stack']);
    final risks = _asListOfStrings(detail['risks']);

    // Screens section is always visible (even empty) so the add button
    // is reachable. Inside ScreensList we render an "add screen" button
    // at the bottom.
    widgets.add(_Section(
      label: '主要画面',
      child: ScreensList(
        screens: screens,
        onEdit: onEdit,
        onAddScreen: onAddScreen,
        onRemoveScreen: onRemoveScreen,
        onDuplicateScreen: onDuplicateScreen,
        onMoveScreen: onMoveScreen,
        onAddSection: onAddSection,
        onRemoveSection: onRemoveSection,
      ),
    ));
    // userFlow は空でも常に表示 (編集で記入できる)
    widgets.add(_Section(
      label: 'ユーザーフロー',
      child: _UserFlowText(text: userFlow ?? '', onEdit: onEdit),
    ));
    // APIs: always-visible so add button is reachable even when list is empty.
    widgets.add(_Section(
      label: 'API / エンドポイント',
      child: ApisList(
        apis: apis,
        onEdit: onEdit,
        onAdd: onAddApi,
        onRemove: onRemoveApi,
      ),
    ));
    // Stack: same.
    widgets.add(_Section(
      label: '技術スタック候補',
      child: StackChips(
        stack: stack,
        onEdit: onEdit,
        onAdd: onAddStack,
        onRemove: onRemoveStack,
      ),
    ));
    // risks は空でも常に表示
    widgets.add(_Section(
      label: 'リスクと論点',
      child: _RisksList(
        risks: risks,
        onEdit: onEdit,
        onAdd: onAddRisk,
        onRemove: onRemoveRisk,
      ),
    ));
    return widgets;
  }
}

/// A Text that, when tapped, opens an edit dialog and calls [onChanged]
/// with the new value. Designed to drop-in replace any Text in the
/// ImportPage body — pencil icon is inlined via WidgetSpan so it does not
/// break surrounding layouts.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.icon,
    required this.title,
    required this.summary,
    required this.prompt,
    required this.onEdit,
  });
  final String icon;
  final String title;
  final String summary;
  final String prompt;
  final EditAtPath onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableField(
          value: icon,
          style: const TextStyle(fontSize: ImportPageStyles.heroIconSize),
          label: 'アイコン (絵文字 1 文字)',
          onChanged: (v) => onEdit(['icon'], v),
        ),
        const SizedBox(height: ImportPageStyles.heroSpacing),
        EditableField(
          value: title,
          style: ImportPageStyles.titleStyle,
          label: 'タイトル',
          onChanged: (v) => onEdit(['title'], v),
        ),
        const SizedBox(height: 12),
        EditableField(
          value: summary,
          style: ImportPageStyles.summaryStyle,
          label: '概要',
          multiline: true,
          onChanged: (v) => onEdit(['summary'], v),
        ),
        if (prompt.isNotEmpty) ...[
          const SizedBox(height: 8),
          // prompt は元プロンプト = 監査証跡なので編集させない
          Text('元のプロンプト: $prompt', style: ImportPageStyles.promptHintStyle),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.meta,
    required this.onEdit,
    required this.onAdd,
    required this.onRemove,
    required this.onCycleColor,
  });
  final List<Map<String, dynamic>> meta;
  final EditAtPath onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onCycleColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...meta.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final label = (m['label'] as String?) ?? '';
          final color = (m['color'] as String?) ?? 'slate';
          final bg = ImportPageStyles.statusBackgrounds[color] ??
              ImportPageStyles.statusBackgrounds['slate']!;
          final fg = ImportPageStyles.statusForegrounds[color] ??
              ImportPageStyles.statusForegrounds['slate']!;
          return Container(
            padding: const EdgeInsets.fromLTRB(8, 3, 3, 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditableField(
                  value: label,
                  style: TextStyle(
                      fontSize: 11,
                      color: fg,
                      fontWeight: FontWeight.w600),
                  label: 'バッジラベル',
                  onChanged: (v) => onEdit(['meta', i, 'label'], v),
                ),
                InkWell(
                  onTap: () => onCycleColor(i),
                  borderRadius: BorderRadius.circular(3),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.palette_outlined, size: 11, color: fg),
                  ),
                ),
                InkWell(
                  onTap: () => onRemove(i),
                  borderRadius: BorderRadius.circular(3),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 11, color: fg),
                  ),
                ),
              ],
            ),
          );
        }),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 11, color: Color(0xFF64748B)),
                SizedBox(width: 3),
                Text(
                  'バッジ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ImportPageStyles.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: ImportPageStyles.sectionLabelStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UserFlowText extends StatelessWidget {
  const _UserFlowText({required this.text, required this.onEdit});
  final String text;
  final EditAtPath onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ImportPageStyles.cardPadding,
      decoration: ImportPageStyles.cardDecoration,
      child: EditableField(
        value: text,
        style: ImportPageStyles.itemBodyStyle,
        label: 'ユーザーフロー',
        multiline: true,
        onChanged: (v) => onEdit(['detail', 'userFlow'], v),
      ),
    );
  }
}

class _RisksList extends StatelessWidget {
  const _RisksList({
    required this.risks,
    required this.onEdit,
    required this.onAdd,
    required this.onRemove,
  });
  final List<String> risks;
  final EditAtPath onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ImportPageStyles.cardPadding,
      decoration: ImportPageStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...risks.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: ImportPageStyles.riskIconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EditableField(
                      value: r,
                      style: ImportPageStyles.itemBodyStyle,
                      label: 'リスク',
                      multiline: true,
                      onChanged: (v) => onEdit(['detail', 'risks', i], v),
                    ),
                  ),
                  InkWell(
                    onTap: () => onRemove(i),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 14, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('リスクを追加'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList(growable: false);
}

List<String> _asListOfStrings(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}
