// ImportPage — React 側 (prototype_engine) で生成したプロジェクトカードを
// URL クエリ ?data=<base64url(json)> 経由で受け取り、Flutter キャンバスで表示する。
// VISION の "思考の直結" を React → Flutter まで一筆書きで繋ぐ受け側。
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
          : _ImportBody(payload: payload, onEdit: _editAtPath),
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
  const _ImportBody({required this.payload, required this.onEdit});
  final Map<String, dynamic> payload;
  final EditAtPath onEdit;

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

    if (screens.isNotEmpty) {
      widgets.add(_Section(
        label: '主要画面',
        child: _ScreensList(screens: screens, onEdit: onEdit),
      ));
    }
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
  const _ScreensList({required this.screens, required this.onEdit});
  final List<Map<String, dynamic>> screens;
  final EditAtPath onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: screens.asMap().entries.map((entry) {
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
              _EditableText(
                value: name,
                style: ImportPageStyles.itemTitleStyle,
                label: '画面名',
                onChanged: (v) =>
                    onEdit(['detail', 'screens', screenIndex, 'name'], v),
              ),
              const SizedBox(height: 4),
              _EditableText(
                value: purpose,
                style: ImportPageStyles.itemBodyStyle,
                label: '画面の目的',
                multiline: true,
                onChanged: (v) =>
                    onEdit(['detail', 'screens', screenIndex, 'purpose'], v),
              ),
              if (sections.isNotEmpty) ...[
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
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionSubCard extends StatelessWidget {
  const _SectionSubCard({
    required this.label,
    required this.body,
    required this.onEditLabel,
    required this.onEditBody,
  });
  final String label;
  final String body;
  final ValueChanged<String> onEditLabel;
  final ValueChanged<String> onEditBody;

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
          _EditableText(
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
