// ImportPage — React 側 (prototype_engine) で生成したプロジェクトカードを
// URL クエリ ?data=<base64url(json)> 経由で受け取り、Flutter キャンバスで表示する。
// VISION の "思考の直結" を React → Flutter まで一筆書きで繋ぐ受け側。
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/utils/url_updater_stub.dart'
    if (dart.library.html) '../../core/utils/url_updater_html.dart';
import 'import_page.styles.dart';
import 'import_page_sheet.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, this.encodedData});

  /// 明示的に data を渡す経路 (テスト用途など)。
  /// null の場合は kIsWeb 環境の Uri.base.queryParameters から自動取得する。
  final String? encodedData;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  Map<String, dynamic>? _payload;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final encoded = widget.encodedData ?? _readEncodedFromUrl();
    _payload = _decodePayload(encoded);
  }

  /// Apply an edit at a nested path within the payload. `path` accepts
  /// `String` for map keys and `int` for list indices, so e.g.
  /// `['detail', 'screens', 0, 'name']` rewrites the first screen's name.
  void _editAtPath(List<Object> path, String newValue) {
    final payload = _payload;
    if (payload == null || path.isEmpty) return;
    setState(() {
      dynamic current = payload;
      for (var i = 0; i < path.length - 1; i++) {
        final key = path[i];
        if (current is Map && key is String) {
          current = current[key];
        } else if (current is List && key is int) {
          current = current[key];
        } else {
          return;
        }
      }
      final last = path.last;
      if (current is Map && last is String) {
        current[last] = newValue;
      } else if (current is List && last is int) {
        current[last] = newValue;
      }
      _dirty = true;
    });
    _persistToUrl();
  }

  /// Ensure `payload.detail.screens` exists and is a growable List, then
  /// return it. Used by structural add/remove helpers.
  List<dynamic>? _ensureScreensList() {
    final payload = _payload;
    if (payload == null) return null;
    var detail = payload['detail'];
    if (detail is! Map<String, dynamic>) {
      detail = <String, dynamic>{};
      payload['detail'] = detail;
    }
    var screens = (detail as Map<String, dynamic>)['screens'];
    if (screens is! List) {
      screens = <dynamic>[];
      detail['screens'] = screens;
    } else if (screens is! List<dynamic>) {
      screens = screens.toList();
      detail['screens'] = screens;
    }
    return screens as List<dynamic>;
  }

  void _addScreen() {
    setState(() {
      final screens = _ensureScreensList();
      if (screens == null) return;
      screens.add(<String, dynamic>{
        'name': '新規画面',
        'purpose': 'この画面で何ができるかを書く',
        'sections': <Map<String, dynamic>>[
          {'label': 'アクション', 'body': 'ユーザーがここで取れる操作'},
          {'label': '表示情報', 'body': 'この画面に表示するデータ'},
        ],
      });
      _dirty = true;
    });
    _persistToUrl();
  }

  void _removeScreen(int index) {
    setState(() {
      final screens = _ensureScreensList();
      if (screens == null || index < 0 || index >= screens.length) return;
      screens.removeAt(index);
      _dirty = true;
    });
    _persistToUrl();
  }

  List<dynamic>? _ensureSectionsList(int screenIndex) {
    final screens = _ensureScreensList();
    if (screens == null || screenIndex < 0 || screenIndex >= screens.length) {
      return null;
    }
    final screen = screens[screenIndex];
    if (screen is! Map<String, dynamic>) return null;
    var sections = screen['sections'];
    if (sections is! List) {
      sections = <Map<String, dynamic>>[];
      screen['sections'] = sections;
    } else if (sections is! List<dynamic>) {
      sections = sections.toList();
      screen['sections'] = sections;
    }
    return sections as List<dynamic>;
  }

  void _addSection(int screenIndex) {
    setState(() {
      final sections = _ensureSectionsList(screenIndex);
      if (sections == null) return;
      sections.add(<String, dynamic>{
        'label': 'ラベル',
        'body': '本文',
      });
      _dirty = true;
    });
    _persistToUrl();
  }

  void _removeSection(int screenIndex, int sectionIndex) {
    setState(() {
      final sections = _ensureSectionsList(screenIndex);
      if (sections == null ||
          sectionIndex < 0 ||
          sectionIndex >= sections.length) {
        return;
      }
      sections.removeAt(sectionIndex);
      _dirty = true;
    });
    _persistToUrl();
  }

  /// Re-encode the current payload and write it back to the browser URL
  /// (Web only). On desktop / mobile the call is a noop via the stub.
  /// Best-effort — if encoding fails we just skip silently.
  void _persistToUrl() {
    final payload = _payload;
    if (payload == null) return;
    try {
      final jsonStr = json.encode(payload);
      final base64 = base64Url.encode(utf8.encode(jsonStr)).replaceAll('=', '');
      updateQueryParameter('data', base64);
    } catch (_) {
      // swallow; never fail an edit because the URL could not update
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
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
            if (_dirty) ...[
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
      ),
      body: payload == null
          ? const _EmptyState()
          : _ImportBody(
              payload: payload,
              onEdit: _editAtPath,
              onAddScreen: _addScreen,
              onRemoveScreen: _removeScreen,
              onAddSection: _addSection,
              onRemoveSection: _removeSection,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'インポートデータを読み取れませんでした',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'URL の ?data= パラメータが正しい base64 形式ではありません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Callback that mutates the payload at a nested path.
/// See `_ImportPageState._editAtPath` for the path format.
typedef EditAtPath = void Function(List<Object> path, String newValue);

class _ImportBody extends StatelessWidget {
  const _ImportBody({
    required this.payload,
    required this.onEdit,
    required this.onAddScreen,
    required this.onRemoveScreen,
    required this.onAddSection,
    required this.onRemoveSection,
  });
  final Map<String, dynamic> payload;
  final EditAtPath onEdit;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onRemoveScreen;
  final ValueChanged<int> onAddSection;
  final void Function(int screenIndex, int sectionIndex) onRemoveSection;

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
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _MetaRow(meta: meta),
                ],
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
    // is reachable. Inside _ScreensList we render an "add screen" button
    // at the bottom.
    widgets.add(_Section(
      label: '主要画面',
      child: _ScreensList(
        screens: screens,
        onEdit: onEdit,
        onAddScreen: onAddScreen,
        onRemoveScreen: onRemoveScreen,
        onAddSection: onAddSection,
        onRemoveSection: onRemoveSection,
      ),
    ));
    if (userFlow != null && userFlow.isNotEmpty) {
      widgets.add(_Section(label: 'ユーザーフロー', child: _UserFlowText(text: userFlow)));
    }
    if (apis.isNotEmpty) {
      widgets.add(_Section(label: 'API / エンドポイント', child: _ApisList(apis: apis)));
    }
    if (stack.isNotEmpty) {
      widgets.add(_Section(label: '技術スタック候補', child: _StackChips(stack: stack)));
    }
    if (risks.isNotEmpty) {
      widgets.add(_Section(label: 'リスクと論点', child: _RisksList(risks: risks)));
    }
    return widgets;
  }
}

/// A Text that, when tapped, opens an edit dialog and calls [onChanged]
/// with the new value. Designed to drop-in replace any Text in the
/// ImportPage body — pencil icon is inlined via WidgetSpan so it does not
/// break surrounding layouts.
class _EditableText extends StatelessWidget {
  const _EditableText({
    required this.value,
    required this.style,
    required this.label,
    required this.onChanged,
    this.multiline = false,
  });
  final String value;
  final TextStyle style;
  final String label;
  final ValueChanged<String> onChanged;
  final bool multiline;

  Future<void> _openEditor(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(
        label: label,
        initialValue: value,
        multiline: multiline,
      ),
    );
    if (result != null && result != value) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditor(context),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value.isEmpty ? '(タップして追加)' : value, style: style),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: Color(0x552563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.label,
    required this.initialValue,
    required this.multiline,
  });
  final String label;
  final String initialValue;
  final bool multiline;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.multiline ? null : 1,
        minLines: widget.multiline ? 3 : 1,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onSubmitted: widget.multiline
            ? null
            : (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

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
        Text(icon, style: const TextStyle(fontSize: ImportPageStyles.heroIconSize)),
        const SizedBox(height: ImportPageStyles.heroSpacing),
        _EditableText(
          value: title,
          style: ImportPageStyles.titleStyle,
          label: 'タイトル',
          onChanged: (v) => onEdit(['title'], v),
        ),
        const SizedBox(height: 12),
        _EditableText(
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
  const _MetaRow({required this.meta});
  final List<Map<String, dynamic>> meta;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: meta.map((m) {
        final label = (m['label'] as String?) ?? '';
        final color = (m['color'] as String?) ?? 'slate';
        final bg = ImportPageStyles.statusBackgrounds[color] ?? ImportPageStyles.statusBackgrounds['slate']!;
        final fg = ImportPageStyles.statusForegrounds[color] ?? ImportPageStyles.statusForegrounds['slate']!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
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

class _ScreensList extends StatelessWidget {
  const _ScreensList({
    required this.screens,
    required this.onEdit,
    required this.onAddScreen,
    required this.onRemoveScreen,
    required this.onAddSection,
    required this.onRemoveSection,
  });
  final List<Map<String, dynamic>> screens;
  final EditAtPath onEdit;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onRemoveScreen;
  final ValueChanged<int> onAddSection;
  final void Function(int screenIndex, int sectionIndex) onRemoveSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...screens.asMap().entries.map((entry) {
          final screenIndex = entry.key;
          final s = entry.value;
          final name = (s['name'] as String?) ?? '';
          final purpose = (s['purpose'] as String?) ?? '';
          final sections = _asListOfMaps(s['sections']);
          return Container(
            margin: const EdgeInsets.only(bottom: ImportPageStyles.itemGap),
            padding: ImportPageStyles.cardPadding,
            decoration: ImportPageStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _EditableText(
                        value: name,
                        style: ImportPageStyles.itemTitleStyle,
                        label: '画面名',
                        onChanged: (v) => onEdit(
                          ['detail', 'screens', screenIndex, 'name'],
                          v,
                        ),
                      ),
                    ),
                    _DeleteIconButton(
                      tooltip: 'この画面を削除',
                      onPressed: () => _confirmRemoveScreen(
                        context,
                        name,
                        () => onRemoveScreen(screenIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _EditableText(
                  value: purpose,
                  style: ImportPageStyles.itemBodyStyle,
                  label: '画面の目的',
                  multiline: true,
                  onChanged: (v) => onEdit(
                    ['detail', 'screens', screenIndex, 'purpose'],
                    v,
                  ),
                ),
                const SizedBox(height: 10),
                ...sections.asMap().entries.map(
                      (secEntry) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _SectionSubCard(
                          label: (secEntry.value['label'] as String?) ?? '',
                          body: (secEntry.value['body'] as String?) ?? '',
                          onEditLabel: (v) => onEdit(
                            [
                              'detail',
                              'screens',
                              screenIndex,
                              'sections',
                              secEntry.key,
                              'label',
                            ],
                            v,
                          ),
                          onEditBody: (v) => onEdit(
                            [
                              'detail',
                              'screens',
                              screenIndex,
                              'sections',
                              secEntry.key,
                              'body',
                            ],
                            v,
                          ),
                          onRemove: () =>
                              onRemoveSection(screenIndex, secEntry.key),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('セクション追加'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                    onPressed: () => onAddSection(screenIndex),
                  ),
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('画面を追加'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onAddScreen,
        ),
      ],
    );
  }
}

Future<void> _confirmRemoveScreen(
  BuildContext context,
  String name,
  VoidCallback onConfirmed,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('画面を削除'),
      content: Text('「${name.isEmpty ? '無題' : name}」を削除しますか?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  if (confirmed == true) onConfirmed();
}

class _DeleteIconButton extends StatelessWidget {
  const _DeleteIconButton({required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _SectionSubCard extends StatelessWidget {
  const _SectionSubCard({
    required this.label,
    required this.body,
    required this.onEditLabel,
    required this.onEditBody,
    required this.onRemove,
  });
  final String label;
  final String body;
  final ValueChanged<String> onEditLabel;
  final ValueChanged<String> onEditBody;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EditableText(
                  value: label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Color(0xFF475569),
                  ),
                  label: 'セクションラベル',
                  onChanged: onEditLabel,
                ),
              ),
              _DeleteIconButton(
                tooltip: 'このセクションを削除',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _EditableText(
            value: body,
            style: ImportPageStyles.itemBodyStyle,
            label: 'セクション本文',
            multiline: true,
            onChanged: onEditBody,
          ),
        ],
      ),
    );
  }
}

class _UserFlowText extends StatelessWidget {
  const _UserFlowText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ImportPageStyles.cardPadding,
      decoration: ImportPageStyles.cardDecoration,
      child: Text(text, style: ImportPageStyles.itemBodyStyle),
    );
  }
}

class _ApisList extends StatelessWidget {
  const _ApisList({required this.apis});
  final List<Map<String, dynamic>> apis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: apis.map((a) {
        final name = (a['name'] as String?) ?? '';
        final description = (a['description'] as String?) ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: ImportPageStyles.itemGap),
          padding: ImportPageStyles.cardPadding,
          decoration: ImportPageStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ImportPageStyles.apiCodeBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(name, style: ImportPageStyles.apiCodeStyle),
              ),
              const SizedBox(height: 6),
              Text(description, style: ImportPageStyles.itemBodyStyle),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StackChips extends StatelessWidget {
  const _StackChips({required this.stack});
  final List<String> stack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stack.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ImportPageStyles.chipBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            s,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ImportPageStyles.chipForeground,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RisksList extends StatelessWidget {
  const _RisksList({required this.risks});
  final List<String> risks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ImportPageStyles.cardPadding,
      decoration: ImportPageStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: risks.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: ImportPageStyles.riskIconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: ImportPageStyles.itemBodyStyle)),
              ],
            ),
          );
        }).toList(),
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
