// DropTargetOverlay — wraps a screen's content area with a DragTarget
// that accepts PaletteItem drops from the widget sidebar. On drop, it
// adds the widget to the screen's payload (for virtual routes) or
// calls the AST insert endpoint (for file-backed routes).

import 'package:flutter/material.dart';

import '../providers/widget_palette_controller.dart';
import 'drop_target_overlay.styles.dart';

class DropTargetOverlay extends StatefulWidget {
  const DropTargetOverlay({
    super.key,
    required this.child,
    required this.onDrop,
  });

  final Widget child;
  /// Called when a PaletteItem is successfully dropped.
  final void Function(PaletteItem item) onDrop;

  @override
  State<DropTargetOverlay> createState() => _DropTargetOverlayState();
}

class _DropTargetOverlayState extends State<DropTargetOverlay> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PaletteItem>(
      onWillAcceptWithDetails: (details) {
        if (!_isHovering) setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        if (_isHovering) setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onDrop(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            widget.child,
            if (_isHovering)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: DropTargetOverlayStyles.hoverBackground,
                    border: Border.all(
                      color: DropTargetOverlayStyles.hoverBorder,
                      width: DropTargetOverlayStyles.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(
                        DropTargetOverlayStyles.borderRadius),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 32,
                            color: DropTargetOverlayStyles.hoverBorder),
                        SizedBox(height: 8),
                        Text('Drop widget here',
                            style: DropTargetOverlayStyles.labelStyle),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
