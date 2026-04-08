// ImportPage — React 側 (prototype_engine) で生成したプロジェクトカードを
// URL クエリ ?data=<base64url(json)> 経由で受け取り、Flutter キャンバスで表示する。
// VISION の "思考の直結" を React → Flutter まで一筆書きで繋ぐ受け側。
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/utils/url_updater_stub.dart'
    if (dart.library.html) '../../core/utils/url_updater_html.dart';
import 'import_page.styles.dart';
import 'import_page_editors.dart';
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

  List<dynamic>? _ensureDetailList(String key) {
    final payload = _payload;
    if (payload == null) return null;
    var detail = payload['detail'];
    if (detail is! Map<String, dynamic>) {
      detail = <String, dynamic>{};
      payload['detail'] = detail;
    }
    var list = (detail as Map<String, dynamic>)[key];
    if (list is! List) {
      list = <dynamic>[];
      detail[key] = list;
    } else if (list is! List<dynamic>) {
      list = list.toList();
      detail[key] = list;
    }
    return list as List<dynamic>;
  }

  void _addApi() {
    setState(() {
      final apis = _ensureDetailList('apis');
      if (apis == null) return;
      apis.add(<String, dynamic>{
        'name': 'GET /endpoint',
        'description': 'この API が返すもの',
      });
      _dirty = true;
    });
    _persistToUrl();
  }

  void _removeApi(int index) {
    setState(() {
      final apis = _ensureDetailList('apis');
      if (apis == null || index < 0 || index >= apis.length) return;
      apis.removeAt(index);
      _dirty = true;
    });
    _persistToUrl();
  }

  void _addStack() {
    setState(() {
      final stack = _ensureDetailList('stack');
      if (stack == null) return;
      stack.add('新規項目');
      _dirty = true;
    });
    _persistToUrl();
  }

  void _removeStack(int index) {
    setState(() {
      final stack = _ensureDetailList('stack');
      if (stack == null || index < 0 || index >= stack.length) return;
      stack.removeAt(index);
      _dirty = true;
    });
    _persistToUrl();
  }

  void _addRisk() {
    setState(() {
      final risks = _ensureDetailList('risks');
      if (risks == null) return;
      risks.add('新しいリスク / 論点');
      _dirty = true;
    });
    _persistToUrl();
  }

  void _removeRisk(int index) {
    setState(() {
      final risks = _ensureDetailList('risks');
      if (risks == null || index < 0 || index >= risks.length) return;
      risks.removeAt(index);
      _dirty = true;
    });
    _persistToUrl();
  }

  /// Initialize a blank payload template so the user can start from
  /// scratch without a React-generated handoff. This is the "zero-to-one"
  /// entry: one empty screen with two placeholder sections.
  void _startBlank() {
    setState(() {
      _payload = <String, dynamic>{
        'title': '新規プロジェクト',
        'icon': '✨',
        'summary': '1〜2 行の概要',
        'prompt': '(手動作成)',
        'meta': <Map<String, dynamic>>[],
        'detail': <String, dynamic>{
          'screens': <Map<String, dynamic>>[
            {
              'name': 'ホーム',
              'purpose': 'この画面の目的',
              'sections': <Map<String, dynamic>>[
                {'label': 'アクション', 'body': 'ユーザーがここで取れる操作'},
                {'label': '表示情報', 'body': 'この画面に表示するデータ'},
              ],
            },
          ],
          'userFlow': '',
          'apis': <Map<String, dynamic>>[],
          'stack': <String>[],
          'risks': <String>[],
        },
      };
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
          ? _EmptyState(onStartBlank: _startBlank)
          : _ImportBody(
              payload: payload,
              onEdit: _editAtPath,
              onAddScreen: _addScreen,
              onRemoveScreen: _removeScreen,
              onAddSection: _addSection,
              onRemoveSection: _removeSection,
              onAddApi: _addApi,
              onRemoveApi: _removeApi,
              onAddStack: _addStack,
              onRemoveStack: _removeStack,
              onAddRisk: _addRisk,
              onRemoveRisk: _removeRisk,
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
    required this.onAddSection,
    required this.onRemoveSection,
    required this.onAddApi,
    required this.onRemoveApi,
    required this.onAddStack,
    required this.onRemoveStack,
    required this.onAddRisk,
    required this.onRemoveRisk,
  });
  final Map<String, dynamic> payload;
  final EditAtPath onEdit;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onRemoveScreen;
  final ValueChanged<int> onAddSection;
  final void Function(int screenIndex, int sectionIndex) onRemoveSection;
  final VoidCallback onAddApi;
  final ValueChanged<int> onRemoveApi;
  final VoidCallback onAddStack;
  final ValueChanged<int> onRemoveStack;
  final VoidCallback onAddRisk;
  final ValueChanged<int> onRemoveRisk;

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
    // is reachable. Inside ScreensList we render an "add screen" button
    // at the bottom.
    widgets.add(_Section(
      label: '主要画面',
      child: ScreensList(
        screens: screens,
        onEdit: onEdit,
        onAddScreen: onAddScreen,
        onRemoveScreen: onRemoveScreen,
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
