// ImportPage — React 側 (prototype_engine) で生成したプロジェクトカードを
// URL クエリ ?data=<base64url(json)> 経由で受け取り、Flutter キャンバスで表示する。
// VISION の "思考の直結" を React → Flutter まで一筆書きで繋ぐ受け側。
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/codegen/page_codegen.dart';
import 'import_page.styles.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({super.key, this.encodedData});

  /// 明示的に data を渡す経路 (テスト用途など)。
  /// null の場合は kIsWeb 環境の Uri.base.queryParameters から自動取得する。
  final String? encodedData;

  @override
  Widget build(BuildContext context) {
    final encoded = encodedData ?? _readEncodedFromUrl();
    final payload = _decodePayload(encoded);

    return Scaffold(
      backgroundColor: ImportPageStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Imported from Prototype Engine',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: payload == null
          ? const _EmptyState()
          : _ImportBody(payload: payload),
      floatingActionButton: payload == null
          ? null
          : _ImportActionButton(payload: payload),
    );
  }
}

class _ImportActionButton extends StatelessWidget {
  const _ImportActionButton({required this.payload});
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
          builder: (ctx) => _GeneratedPagesSheet(pages: pages),
        );
      },
    );
  }
}

class _GeneratedPagesSheet extends StatelessWidget {
  const _GeneratedPagesSheet({required this.pages});
  final List<GeneratedPage> pages;

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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pages.length * 2} 個のファイルを生成しました',
                      style: ImportPageStyles.itemTitleStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: const Text('全てコピー'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _combinedSource),
                      );
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('クリップボードにコピーしました'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                itemCount: pages.length * 2,
                itemBuilder: (ctx, index) {
                  final page = pages[index ~/ 2];
                  final file = index.isEven ? page.dart : page.styles;
                  return _GeneratedFileBlock(file: file);
                },
              ),
            ),
          ],
        );
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

class _ImportBody extends StatelessWidget {
  const _ImportBody({required this.payload});
  final Map<String, dynamic> payload;

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
                _Hero(icon: icon, title: title, summary: summary, prompt: prompt),
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
      widgets.add(_Section(label: '主要画面', child: _ScreensList(screens: screens)));
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

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.summary, required this.prompt});
  final String icon;
  final String title;
  final String summary;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: ImportPageStyles.heroIconSize)),
        const SizedBox(height: ImportPageStyles.heroSpacing),
        Text(title, style: ImportPageStyles.titleStyle),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(summary, style: ImportPageStyles.summaryStyle),
        ],
        if (prompt.isNotEmpty) ...[
          const SizedBox(height: 8),
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
  const _ScreensList({required this.screens});
  final List<Map<String, dynamic>> screens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: screens.map((s) {
        final name = (s['name'] as String?) ?? '';
        final purpose = (s['purpose'] as String?) ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: ImportPageStyles.itemGap),
          padding: ImportPageStyles.cardPadding,
          decoration: ImportPageStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: ImportPageStyles.itemTitleStyle),
              const SizedBox(height: 4),
              Text(purpose, style: ImportPageStyles.itemBodyStyle),
            ],
          ),
        );
      }).toList(),
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
