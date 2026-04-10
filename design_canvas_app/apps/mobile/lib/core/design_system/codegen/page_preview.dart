// Live Flutter Widget preview that mirrors the source produced by
// `page_codegen.dart`. The two must stay in lockstep — if you change the
// generated Dart template, change this widget, and vice versa.
//
// Rationale: on Flutter Web we cannot write files to the host filesystem,
// so the user has no way to "see" the generated page short of copying
// source into their local checkout. This widget closes the feedback loop
// by rendering the exact same layout live, from the same payload.

import 'package:flutter/material.dart';

import '../../sandbox/inspectable.dart';
import '../tokens.dart';

class GeneratedPagePreview extends StatelessWidget {
  const GeneratedPagePreview({
    super.key,
    required this.screen,
    this.projectTitle = '',
    this.icon = '',
    this.meta = const [],
    this.apis = const [],
    this.stack = const [],
  });

  /// Same shape as the entries in `detail.screens` in the handoff payload:
  /// `{ "name": String, "purpose": String }`.
  final Map<String, dynamic> screen;

  /// Project-level context shared across screens — mirrored from the
  /// top-level handoff payload.
  final String projectTitle;
  final String icon;
  final List<Map<String, dynamic>> meta;
  final List<Map<String, dynamic>> apis;
  final List<String> stack;

  /// Stable ID prefix derived from screen name — used to make each
  /// widget Cmd+Click selectable on the design canvas.
  String get _idPrefix {
    final raw = ((screen['name'] as String?) ?? 'screen').trim();
    return raw.isEmpty ? 'screen' : raw.replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final name = ((screen['name'] as String?) ?? '').trim();
    final purpose = ((screen['purpose'] as String?) ?? '').trim();
    final displayName = name.isEmpty ? '(名称未定)' : name;
    final headerText = projectTitle.isEmpty ? displayName : projectTitle;
    final screenSections = _readScreenSections(screen);
    final prefix = _idPrefix;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Inspectable(
          id: '__Text__${prefix}_appbar',
          isText: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon.isNotEmpty) ...[
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  headerText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTokens.spaceL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Inspectable(
              id: '__Text__${prefix}_heading',
              isText: true,
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: AppTokens.fontHeadingL,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.colorTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceS),
            Inspectable(
              id: '__Text__${prefix}_purpose',
              isText: true,
              child: Text(
                purpose.isEmpty ? '(目的未記入)' : purpose,
                style: const TextStyle(
                  fontSize: AppTokens.fontBodyM,
                  height: 1.6,
                  color: AppTokens.colorTextSecondary,
                ),
              ),
            ),
            if (screenSections.isNotEmpty) ...[
              const SizedBox(height: _sectionGap),
              const _SectionLabel('この画面について'),
              const SizedBox(height: 12),
              ..._buildSectionCards(screenSections),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: _sectionGap),
              Inspectable(id: '${prefix}_meta', child: _MetaRow(meta: meta)),
            ],
            if (apis.isNotEmpty) ...[
              const SizedBox(height: _sectionGap),
              const _SectionLabel('関連 API'),
              const SizedBox(height: 12),
              ..._buildApiCards(apis),
            ],
            if (stack.isNotEmpty) ...[
              const SizedBox(height: _sectionGap),
              const _SectionLabel('使用スタック'),
              const SizedBox(height: 12),
              Inspectable(
                  id: '${prefix}_stack', child: _StackChips(stack: stack)),
            ],
          ],
        ),
      ),
    );
  }

  static const double _sectionGap = 24;

  static List<Map<String, dynamic>> _readScreenSections(
      Map<String, dynamic> screen) {
    final raw = screen['sections'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<Widget> _buildSectionCards(List<Map<String, dynamic>> sections) {
    final prefix = _idPrefix;
    return sections.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final label = (s['label'] as String?) ?? '';
      final body = (s['body'] as String?) ?? '';
      return Inspectable(
        id: '${prefix}_section_$i',
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Inspectable(
                id: '__Text__${prefix}_section_${i}_label',
                isText: true,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Inspectable(
                id: '__Text__${prefix}_section_${i}_body',
                isText: true,
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: AppTokens.fontBodyM,
                    height: 1.6,
                    color: AppTokens.colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildApiCards(List<Map<String, dynamic>> apiList) {
    final prefix = _idPrefix;
    return apiList.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      final apiName = (a['name'] as String?) ?? '';
      final description = (a['description'] as String?) ?? '';
      return Inspectable(
        id: '${prefix}_api_$i',
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Inspectable(
                id: '__Text__${prefix}_api_${i}_name',
                isText: true,
                child: Text(
                  apiName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppTokens.fontBodyM,
                  height: 1.6,
                  color: AppTokens.colorTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.meta});
  final List<Map<String, dynamic>> meta;

  static const _statusBg = {
    'green': Color(0xFFD1FAE5),
    'blue': Color(0xFFDBEAFE),
    'yellow': Color(0xFFFEF3C7),
    'slate': Color(0xFFF1F5F9),
  };
  static const _statusFg = {
    'green': Color(0xFF047857),
    'blue': Color(0xFF1D4ED8),
    'yellow': Color(0xFF92400E),
    'slate': Color(0xFF475569),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: meta.map((m) {
        final label = (m['label'] as String?) ?? '';
        final color = (m['color'] as String?) ?? 'slate';
        final bg = _statusBg[color] ?? _statusBg['slate']!;
        final fg = _statusFg[color] ?? _statusFg['slate']!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
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
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            s,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A phone-shaped container that isolates [child] from the surrounding
/// theme and gives it a realistic "preview window" look. Used by the
/// ImportPage bottom sheet.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.width = 320,
    this.height = 568,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: ThemeData.light(useMaterial3: true),
        child: Material(child: child),
      ),
    );
  }
}
