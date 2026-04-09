// Small decorative widgets used by the canvas editor background.
// Extracted from `design_canvas_page.dart` for file-size discipline.

import 'package:flutter/material.dart';

/// A soft radial-gradient circle. Used in `design_canvas_page.dart` as
/// atmospheric background decor behind the device previews.
Widget buildCanvasDecorCircle(Color color, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color, color.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ),
    ),
  );
}
