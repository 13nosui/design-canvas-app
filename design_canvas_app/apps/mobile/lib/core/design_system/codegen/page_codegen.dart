// Pure, top-level code generators that turn a screen payload (from the
// React prototype_engine handoff) into a `.dart` + `.styles.dart` pair
// that follows ADR-0005 (Component File Separation).
//
// This file has NO Flutter runtime deps — just string composition. The
// outputs are source files that will be written to disk by the caller,
// or copied to clipboard, or previewed in UI.
//
// Shape of the input (subset of the handoff payload):
//   {
//     "title":  "タスク管理アプリ",
//     "detail": {
//       "screens": [
//         { "name": "ダッシュボード", "purpose": "今日やるべきタスクを俯瞰する" },
//         ...
//       ]
//     }
//   }

/// A single generated file. `path` is relative to `lib/` and uses forward
/// slashes. `content` is the full UTF-8 source.
class GeneratedFile {
  final String path;
  final String content;
  const GeneratedFile({required this.path, required this.content});
}

/// A `.dart` + `.styles.dart` pair produced from one screen.
class GeneratedPage {
  final GeneratedFile dart;
  final GeneratedFile styles;
  final String className;
  final String slug;

  /// The raw screen payload this page was generated from. Exposed so that
  /// UIs can render a live preview (see `page_preview.dart`) from the
  /// exact same input, without re-parsing the generated Dart source.
  final Map<String, dynamic> sourceScreen;

  const GeneratedPage({
    required this.dart,
    required this.styles,
    required this.className,
    required this.slug,
    required this.sourceScreen,
  });
}

/// Turn one screen into a page pair. `projectSlug` is used as the parent
/// directory under `lib/presentation/generated/`. Both slugs are snake_case.
///
/// Optional project-wide context (title, icon, meta, apis, stack) is shared
/// across all screens in the same payload. Empty context values cause the
/// corresponding sections to be omitted from the generated page — the
/// generator produces the same minimal "title + purpose" page as before
/// when no rich context is supplied.
GeneratedPage generatePageFromScreen({
  required String projectSlug,
  required Map<String, dynamic> screen,
  String projectTitle = '',
  String icon = '',
  List<Map<String, dynamic>> meta = const [],
  List<Map<String, dynamic>> apis = const [],
  List<String> stack = const [],
  int fallbackIndex = 0,
}) {
  final rawName = (screen['name'] as String?)?.trim() ?? '';
  final purpose = (screen['purpose'] as String?)?.trim() ?? '';

  final name = rawName.isEmpty ? 'Screen $fallbackIndex' : rawName;
  final slug = _slugify(name, fallback: 'screen_$fallbackIndex');
  final className = _pascalCase(name, fallback: 'Screen$fallbackIndex');

  final dir = 'presentation/generated/$projectSlug';
  final dartPath = '$dir/${slug}_page.dart';
  final stylesPath = '$dir/${slug}_page.styles.dart';

  final dartContent = _buildDartContent(
    className: className,
    slug: slug,
    screenName: name,
    purpose: purpose,
    projectTitle: projectTitle,
    icon: icon,
    meta: meta,
    apis: apis,
    stack: stack,
  );
  final stylesContent = _buildStylesContent(className: className);

  return GeneratedPage(
    dart: GeneratedFile(path: dartPath, content: dartContent),
    styles: GeneratedFile(path: stylesPath, content: stylesContent),
    className: className,
    slug: slug,
    sourceScreen: screen,
  );
}

/// Turn all `detail.screens` in a handoff payload into page pairs.
/// Returns an empty list if the payload has no screens. Project-wide
/// context (title, icon, meta, apis, stack) is extracted from the payload
/// and shared across every generated page.
List<GeneratedPage> generatePagesFromPayload(Map<String, dynamic> payload) {
  final title = (payload['title'] as String?) ?? '';
  final icon = (payload['icon'] as String?) ?? '';
  final projectSlug = _slugify(title, fallback: 'imported');

  final meta = _asListOfMaps(payload['meta']);

  final detail = payload['detail'];
  if (detail is! Map<String, dynamic>) return const [];
  final rawScreens = detail['screens'];
  if (rawScreens is! List) return const [];

  final apis = _asListOfMaps(detail['apis']);
  final stack = _asListOfStrings(detail['stack']);

  final result = <GeneratedPage>[];
  var i = 0;
  for (final s in rawScreens) {
    if (s is Map) {
      result.add(generatePageFromScreen(
        projectSlug: projectSlug,
        screen: s.cast<String, dynamic>(),
        projectTitle: title,
        icon: icon,
        meta: meta,
        apis: apis,
        stack: stack,
        fallbackIndex: i,
      ));
    }
    i++;
  }
  return result;
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

// ---------------------------------------------------------------------------
// Naming helpers

/// snake_case slug. Non-ASCII and punctuation are stripped. Falls back to
/// [fallback] if the result is empty.
String _slugify(String input, {required String fallback}) {
  final buffer = StringBuffer();
  var lastWasSeparator = true;
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final isLower = rune >= 0x61 && rune <= 0x7A;
    final isUpper = rune >= 0x41 && rune <= 0x5A;
    final isDigit = rune >= 0x30 && rune <= 0x39;
    if (isLower || isDigit) {
      buffer.write(ch);
      lastWasSeparator = false;
    } else if (isUpper) {
      buffer.write(ch.toLowerCase());
      lastWasSeparator = false;
    } else {
      if (!lastWasSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }
  }
  var out = buffer.toString();
  while (out.endsWith('_')) {
    out = out.substring(0, out.length - 1);
  }
  return out.isEmpty ? fallback : out;
}

/// PascalCase identifier. Mirrors [_slugify] but capitalizes each chunk.
String _pascalCase(String input, {required String fallback}) {
  final slug = _slugify(input, fallback: '');
  if (slug.isEmpty) return fallback;
  return slug
      .split('_')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join();
}

// Exposed for tests.
String slugifyForTest(String input) => _slugify(input, fallback: 'x');
String pascalCaseForTest(String input) => _pascalCase(input, fallback: 'X');

// ---------------------------------------------------------------------------
// Source builders

String _escapeSingleQuotes(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _buildDartContent({
  required String className,
  required String slug,
  required String screenName,
  required String purpose,
  required String projectTitle,
  required String icon,
  required List<Map<String, dynamic>> meta,
  required List<Map<String, dynamic>> apis,
  required List<String> stack,
}) {
  final nameLit = _escapeSingleQuotes(screenName);
  final purposeLit = _escapeSingleQuotes(purpose);
  final headerLit = _escapeSingleQuotes(
    projectTitle.isEmpty ? screenName : projectTitle,
  );

  final appBarLeading = icon.isEmpty
      ? "const Text('$headerLit', style: ${className}PageStyles.appBarTitleStyle)"
      : '''Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('${_escapeSingleQuotes(icon)}', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('$headerLit', style: ${className}PageStyles.appBarTitleStyle),
          ],
        )''';

  final metaBlock = _buildMetaBlock(className, meta);
  final apisBlock = _buildApisBlock(className, apis);
  final stackBlock = _buildStackBlock(className, stack);

  final sections = <String>[
    if (metaBlock.isNotEmpty) metaBlock,
    if (apisBlock.isNotEmpty) apisBlock,
    if (stackBlock.isNotEmpty) stackBlock,
  ];
  final sectionsJoined = sections.isEmpty
      ? ''
      : sections
          .map((s) =>
              '            const SizedBox(height: ${className}PageStyles.sectionGap),\n$s')
          .join('\n');

  return '''// GENERATED by page_codegen.dart — safe to edit manually.
// This file follows ADR-0005: the layout skeleton lives here, all visual
// constants live in `${slug}_page.styles.dart`.

import 'package:flutter/material.dart';

import '${slug}_page.styles.dart';

class ${className}Page extends StatelessWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ${className}PageStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: ${className}PageStyles.appBarBackground,
        elevation: 0,
        title: $appBarLeading,
      ),
      body: SingleChildScrollView(
        padding: ${className}PageStyles.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$nameLit',
              style: ${className}PageStyles.titleStyle,
            ),
            const SizedBox(height: ${className}PageStyles.titleGap),
            Text(
              '$purposeLit',
              style: ${className}PageStyles.bodyStyle,
            ),
$sectionsJoined
          ],
        ),
      ),
    );
  }
}
''';
}

String _buildMetaBlock(String className, List<Map<String, dynamic>> meta) {
  if (meta.isEmpty) return '';
  final children = meta.map((m) {
    final label = _escapeSingleQuotes((m['label'] as String?) ?? '');
    final color = (m['color'] as String?) ?? 'slate';
    return '''              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ${className}PageStyles.statusBg${_capitalize(color)},
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$label',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ${className}PageStyles.statusFg${_capitalize(color)},
                  ),
                ),
              ),''';
  }).join('\n');

  return '''            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
$children
              ],
            ),''';
}

String _buildApisBlock(String className, List<Map<String, dynamic>> apis) {
  if (apis.isEmpty) return '';
  final cards = apis.map((a) {
    final name = _escapeSingleQuotes((a['name'] as String?) ?? '');
    final desc =
        _escapeSingleQuotes((a['description'] as String?) ?? '');
    return '''            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: ${className}PageStyles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name', style: ${className}PageStyles.apiCodeStyle),
                  const SizedBox(height: 4),
                  Text('$desc', style: ${className}PageStyles.bodyStyle),
                ],
              ),
            ),''';
  }).join('\n');

  return '''            Text('関連 API', style: ${className}PageStyles.sectionLabelStyle),
            const SizedBox(height: 12),
$cards''';
}

String _buildStackBlock(String className, List<String> stack) {
  if (stack.isEmpty) return '';
  final chips = stack.map((s) {
    return '''              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ${className}PageStyles.chipBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '${_escapeSingleQuotes(s)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ${className}PageStyles.chipForeground,
                  ),
                ),
              ),''';
  }).join('\n');

  return '''            Text('使用スタック', style: ${className}PageStyles.sectionLabelStyle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
$chips
              ],
            ),''';
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _buildStylesContent({required String className}) {
  return '''// GENERATED by page_codegen.dart — canvas editor writes back to this file.
// ADR-0005: only static const visual constants here. No Provider, no logic.

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';

class ${className}PageStyles {
  static const backgroundColor =
      Color(0xFFF8F9FA); // TODO: New Token Candidate - colorPageBg
  static const appBarBackground =
      Color(0xFFFFFFFF); // TODO: New Token Candidate - colorAppBarBg

  static const contentPadding = AppTokens.spaceL;

  static const appBarTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTokens.colorTextPrimary,
  );

  static const titleStyle = TextStyle(
    fontSize: AppTokens.fontHeadingL,
    fontWeight: FontWeight.w700,
    color: AppTokens.colorTextPrimary,
  );

  static const titleGap = AppTokens.spaceS;
  static const sectionGap = 24.0; // TODO: New Token Candidate - spaceSection

  static const bodyStyle = TextStyle(
    fontSize: AppTokens.fontBodyM,
    height: 1.6,
    color: AppTokens.colorTextSecondary,
  );

  static const sectionLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Color(0xFF64748B), // TODO: New Token Candidate - colorTextSectionLabel
  );

  // Meta status badges (mirrors prototype_engine Badge colors).
  static const statusBgGreen = Color(0xFFD1FAE5);
  static const statusFgGreen = Color(0xFF047857);
  static const statusBgBlue = Color(0xFFDBEAFE);
  static const statusFgBlue = Color(0xFF1D4ED8);
  static const statusBgYellow = Color(0xFFFEF3C7);
  static const statusFgYellow = Color(0xFF92400E);
  static const statusBgSlate = Color(0xFFF1F5F9);
  static const statusFgSlate = Color(0xFF475569);

  // API card.
  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: const Color(0xFFE2E8F0), // TODO: New Token Candidate - colorBorderSubtle
    ),
  );
  static const apiCodeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1D4ED8),
  );

  // Stack chip.
  static const chipBackground = Color(0xFFF1F5F9);
  static const chipForeground = Color(0xFF334155);
}
''';
}
