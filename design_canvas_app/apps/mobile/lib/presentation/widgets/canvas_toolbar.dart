// CanvasToolbar — Figma-style 3-section toolbar.
// Left: sidebar toggle + title
// Center: device mode + zoom controls
// Right: dark mode + connectors + panel toggle

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/theme_controller.dart';
import '../providers/canvas_layout_controller.dart';
import '../providers/widget_palette_controller.dart';
import 'canvas_toolbar.styles.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    super.key,
    required this.transformationController,
  });

  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<CanvasLayoutController>();
    final palette = context.watch<WidgetPaletteController>();
    final themeController = ThemeControllerProvider.of(context);

    // Extract current zoom from transformation matrix
    final matrix = transformationController.value;
    final currentZoom = matrix.getMaxScaleOnAxis();
    final zoomPercent = (currentZoom * 100).round();

    return Container(
      height: CanvasToolbarStyles.height,
      padding: CanvasToolbarStyles.padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          bottom: BorderSide(
              color: CanvasToolbarStyles.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Left section ──
          IconButton(
            icon: Icon(
              palette.isOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
              size: 18,
            ),
            tooltip: 'Widget Palette',
            onPressed: palette.toggleSidebar,
          ),
          const Text('Design Canvas',
              style: CanvasToolbarStyles.titleStyle),

          const Spacer(),

          // ── Center section ──
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            tooltip: 'Zoom Out',
            onPressed: () => _zoom(layout, currentZoom * 0.8),
          ),
          Text('$zoomPercent%', style: CanvasToolbarStyles.zoomStyle),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'Zoom In',
            onPressed: () => _zoom(layout, currentZoom * 1.25),
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 16),
            tooltip: 'Fit All',
            onPressed: () => _fitAll(),
          ),
          const SizedBox(width: 8),
          // Device mode
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(
                    value: PreviewMode.free,
                    label: Text('Free', style: TextStyle(fontSize: 11))),
                ButtonSegment(
                    value: PreviewMode.iphone15,
                    label: Text('iPhone', style: TextStyle(fontSize: 11))),
                ButtonSegment(
                    value: PreviewMode.pixel7,
                    label: Text('Pixel', style: TextStyle(fontSize: 11))),
                ButtonSegment(
                    value: PreviewMode.allDevices,
                    label: Text('All', style: TextStyle(fontSize: 11))),
              ],
              selected: {layout.previewMode},
              onSelectionChanged: (s) => layout.setPreviewMode(s.first),
            ),
          ),

          const Spacer(),

          // ── Right section ──
          IconButton(
            icon: Icon(
              themeController.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              size: 18,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: () => themeController.updateTheme(
                mode: themeController.themeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light),
          ),
          IconButton(
            icon: Icon(
              layout.showConnectors ? Icons.timeline : Icons.timeline_outlined,
              size: 18,
            ),
            tooltip: 'Toggle Connectors',
            onPressed: () =>
                layout.setShowConnectors(!layout.showConnectors),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, size: 18),
            tooltip: 'Toggle Properties Panel',
            onPressed: layout.togglePanel,
          ),
        ],
      ),
    );
  }

  void _zoom(CanvasLayoutController layout, double targetScale) {
    final clamped = targetScale.clamp(0.05, 3.0);
    final current = transformationController.value;
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale == 0) return;
    final scaleFactor = clamped / currentScale;
    transformationController.value = current.clone()..scale(scaleFactor);
  }

  void _fitAll() {
    transformationController.value = Matrix4.identity()
      ..scale(0.3)
      ..translate(50.0, 50.0);
  }
}
