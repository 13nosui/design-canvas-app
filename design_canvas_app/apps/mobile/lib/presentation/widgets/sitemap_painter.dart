import 'package:flutter/material.dart';

import '../../core/navigation/canvas_link.dart';

/// Draws static sitemap edges and dynamic CanvasLink arrows between device
/// previews on the design canvas. Extracted from design_canvas_page.dart to
/// keep the page file focused on state + build.
class SitemapPainter extends CustomPainter {
  final Map<String, List<String>> sitemap;
  final Map<String, Offset> positions;
  final Map<String, CanvasLinkData> dynamicLinks;
  final double screenWidth;
  final double screenHeight;
  final Color lineColor;

  SitemapPainter({
    required this.sitemap,
    required this.positions,
    required this.dynamicLinks,
    required this.screenWidth,
    required this.screenHeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    void drawArrow(Offset start, Offset end, bool fromRight) {
      final path = Path();
      if (fromRight) {
        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          start.dx + 50,
          start.dy,
          end.dx - 50,
          end.dy,
          end.dx,
          end.dy,
        );
      } else {
        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          start.dx - 50,
          start.dy,
          end.dx - 50,
          end.dy,
          end.dx,
          end.dy,
        );
      }

      canvas.drawPath(path, paint);

      // Arrowhead
      final headPath = Path()
        ..moveTo(end.dx - 12, end.dy - 6)
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx - 12, end.dy + 6)
        ..close();
      canvas.drawPath(headPath, arrowPaint);
    }

    // Draw static hierarchy & link lines
    for (final fromNode in sitemap.keys) {
      final fromPos = positions[fromNode];
      if (fromPos == null) continue;

      final startPoint =
          Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

      for (final toNode in sitemap[fromNode]!) {
        final toPos = positions[toNode];
        if (toPos == null) continue;

        final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);
        drawArrow(startPoint, endPoint, true);
      }
    }

    // Draw dynamic CanvasLink lines
    for (final link in dynamicLinks.values) {
      final toPos = positions[link.targetRoute];
      if (toPos == null) continue;

      final startPoint = link.sourceCenter;
      final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);
      // Whether it is coming from right or left
      final fromRight = startPoint.dx < endPoint.dx;

      drawArrow(startPoint, endPoint, fromRight);
    }
  }

  @override
  bool shouldRepaint(covariant SitemapPainter oldDelegate) {
    return oldDelegate.screenWidth != screenWidth ||
        oldDelegate.screenHeight != screenHeight ||
        oldDelegate.sitemap != sitemap ||
        oldDelegate.dynamicLinks != dynamicLinks ||
        oldDelegate.positions != positions ||
        oldDelegate.lineColor != lineColor;
  }
}
