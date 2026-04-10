// ShortcutHelpOverlay — modal showing keyboard shortcuts.
// Triggered by pressing '?' on the canvas.

import 'package:flutter/material.dart';

class ShortcutHelpOverlay extends StatelessWidget {
  const ShortcutHelpOverlay({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const ShortcutHelpOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.keyboard, size: 20),
                const SizedBox(width: 8),
                const Text('Keyboard Shortcuts',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ..._shortcuts.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: Wrap(
                          spacing: 4,
                          children: s.keys
                              .map((k) => _KeyCap(label: k))
                              .toList(),
                        ),
                      ),
                      Expanded(
                        child: Text(s.description,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ShortcutEntry {
  final List<String> keys;
  final String description;
  const _ShortcutEntry(this.keys, this.description);
}

const _shortcuts = [
  _ShortcutEntry(['Cmd/Ctrl', 'Click'], 'Select a widget'),
  _ShortcutEntry(['T'], 'Edit selected text'),
  _ShortcutEntry(['Shift', 'P'], 'Wrap with Padding'),
  _ShortcutEntry(['Shift', 'C'], 'Wrap with Center'),
  _ShortcutEntry(['Shift', 'U'], 'Unwrap parent'),
  _ShortcutEntry(['Shift', 'N'], 'Insert new element'),
  _ShortcutEntry(['Cmd/Ctrl', 'D'], 'Duplicate widget'),
  _ShortcutEntry(['Double-tap'], 'Zoom to screen / Edit virtual route'),
  _ShortcutEntry(['?'], 'Show this help'),
];

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: Color(0xFF334155))),
    );
  }
}
