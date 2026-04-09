// Commit dialog for the canvas editor. Extracted from
// `design_canvas_page.dart` to shrink that file. Presents a pre-filled
// commit message editor and, on confirmation, POSTs to a local git
// server (see scripts/local_git_server.dart) to commit + push.
//
// The function returns a Future that completes when the dialog closes.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/design_system/theme_controller.dart';

/// Show a modal commit dialog. The parent widget must still be mounted
/// before calling. Snackbars are shown via [parentContext].
Future<void> showCanvasCommitDialog(
  BuildContext parentContext,
  ThemeControllerProvider themeController,
) async {
  final hexColor =
      '#${themeController.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  final initialMessage =
      'style: UIデザインの更新 (Color: $hexColor, Radius: ${themeController.borderRadius.toStringAsFixed(1)}px)';
  final controller = TextEditingController(text: initialMessage);
  bool isSubmitting = false;

  await showDialog<void>(
    context: parentContext,
    barrierDismissible: false,
    builder: (diagContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('🚀 Auto-Commit Design'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '現在のデザイン変更をローカルGitサーバー経由でコミット＆プッシュします。\nコミットメッセージを編集してください：',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Commit Message',
                  ),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Pushing to GitHub...'),
                ],
              ],
            ),
            actions: [
              if (!isSubmitting)
                TextButton(
                  onPressed: () => Navigator.of(diagContext).pop(),
                  child: const Text('Cancel'),
                ),
              if (!isSubmitting)
                FilledButton(
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    setState(() {
                      isSubmitting = true;
                    });

                    try {
                      final uri = Uri.parse('http://localhost:8080/commit');
                      final response = await http.post(
                        uri,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'message': controller.text}),
                      );

                      if (!diagContext.mounted) return;
                      Navigator.of(diagContext).pop();

                      if (!parentContext.mounted) return;
                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content:
                                Text('✅ Successfully Pushed to GitHub!'),
                          ),
                        );
                      } else {
                        final err = jsonDecode(response.body)['error'];
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $err'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!diagContext.mounted) return;
                      Navigator.of(diagContext).pop();
                      if (!parentContext.mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            '❌ サーバーに接続できません (local_git_server.dart を起動していますか？)\n$e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm & Push'),
                ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
}
