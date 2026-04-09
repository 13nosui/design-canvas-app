// CanvasDevicePreview — one of the device-frame previews that the canvas
// editor lays out in a grid. Extracted from `design_canvas_page.dart`
// to keep that file under size limits. Renders a route label + inspector
// button + IDE-open button above a phone-shaped frame containing
// [content].

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app/router.dart';
import '../../core/design_system/device_specs.dart';

class CanvasDevicePreview extends StatelessWidget {
  const CanvasDevicePreview({
    super.key,
    required this.device,
    required this.route,
    required this.content,
    required this.onLoadInspector,
  });

  final DeviceSpec device;
  final AppRouteDef? route;
  final Widget content;

  /// Called when the user taps the 🎨 Inspect button. The argument is
  /// the `filePath` from the route.
  final void Function(String filePath) onLoadInspector;

  Future<void> _openInIde(BuildContext context, String? filePath) async {
    try {
      await http.post(
        Uri.parse('http://localhost:8080/open-ide'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'filePath': filePath}),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ IDEを開けません: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (route != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🏷️ ${route!.path} (${route!.name ?? route!.path})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (route!.filePath != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Inspect Styles',
                    child: IconButton(
                      icon: const Text('🎨', style: TextStyle(fontSize: 16)),
                      onPressed: () => onLoadInspector(route!.filePath!),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Open in IDE',
                    child: IconButton(
                      icon: const Text('💻', style: TextStyle(fontSize: 16)),
                      onPressed: () => _openInIde(context, route!.filePath),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          Container(
            width: device.width,
            height: device.height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(device.borderRadius),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                  offset: Offset(0, 15),
                )
              ],
            ),
            padding: EdgeInsets.all(device.bezelWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                (device.borderRadius - device.bezelWidth)
                    .clamp(0.0, double.infinity),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
