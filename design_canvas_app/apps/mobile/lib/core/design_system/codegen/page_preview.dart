// Live Flutter Widget preview that mirrors the source produced by
// `page_codegen.dart`. The two must stay in lockstep — if you change the
// generated Dart template, change this widget, and vice versa.
//
// Rationale: on Flutter Web we cannot write files to the host filesystem,
// so the user has no way to "see" the generated page short of copying
// source into their local checkout. This widget closes the feedback loop
// by rendering the exact same layout live, from the same payload.
//
// Kept styleless on its own — the caller places it inside a phone-shaped
// frame so the preview reads as "this is a page", not "this is a section
// of the bottom sheet".

import 'package:flutter/material.dart';

import '../tokens.dart';

class GeneratedPagePreview extends StatelessWidget {
  const GeneratedPagePreview({super.key, required this.screen});

  /// Same shape as the entries in `detail.screens` in the handoff payload:
  /// `{ "name": String, "purpose": String }`. Missing fields are rendered
  /// with safe fallbacks so an incomplete payload still produces a page.
  final Map<String, dynamic> screen;

  @override
  Widget build(BuildContext context) {
    final name = ((screen['name'] as String?) ?? '').trim();
    final purpose = ((screen['purpose'] as String?) ?? '').trim();
    final displayName = name.isEmpty ? '(名称未定)' : name;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          displayName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTokens.colorTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTokens.spaceL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: AppTokens.fontHeadingL,
                fontWeight: FontWeight.w700,
                color: AppTokens.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceS),
            Text(
              purpose.isEmpty ? '(目的未記入)' : purpose,
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
  }
}

/// A phone-shaped container that isolates [child] from the surrounding
/// theme and gives it a realistic "preview window" look. Used by the
/// ImportPage bottom sheet.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.width = 320, this.height = 568});

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
