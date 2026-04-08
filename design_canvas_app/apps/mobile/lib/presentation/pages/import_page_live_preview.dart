// Horizontally scrollable strip of PhoneFrame previews that updates live
// as the user edits the payload on ImportPage. Computed fresh on every
// build — this is the Web-friendly answer to "see your edit immediately
// without opening the bottom sheet".
//
// Split out of `import_page.dart` to keep that file under the 800-line
// rule.

import 'package:flutter/material.dart';

import '../../core/design_system/codegen/page_codegen.dart';
import '../../core/design_system/codegen/page_preview.dart';

class LivePreviewPanel extends StatelessWidget {
  const LivePreviewPanel({super.key, required this.payload});
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final pages = generatePagesFromPayload(payload);
    final projectTitle = (payload['title'] as String?) ?? '';
    final icon = (payload['icon'] as String?) ?? '';
    final meta = _asMaps(payload['meta']);
    final detail = payload['detail'];
    final apis = (detail is Map)
        ? _asMaps(detail['apis'])
        : const <Map<String, dynamic>>[];
    final stack = (detail is Map)
        ? ((detail['stack'] is List)
            ? (detail['stack'] as List).whereType<String>().toList()
            : const <String>[])
        : const <String>[];

    return Container(
      height: 360,
      color: const Color(0xFFEEF2F7),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: pages.isEmpty
          ? const Center(
              child: Text(
                '画面がまだありません。追加するとここに live preview が表示されます。',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) {
                final page = pages[i];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${page.className}Page',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PhoneFrame(
                      width: 180,
                      height: 300,
                      child: GeneratedPagePreview(
                        screen: page.sourceScreen,
                        projectTitle: projectTitle,
                        icon: icon,
                        meta: meta,
                        apis: apis,
                        stack: stack,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  static List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }
}
