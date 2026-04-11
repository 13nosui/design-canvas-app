// CanvasMinimap — bird's-eye overview in the bottom-right corner.
// Shows all screens as small rectangles. The blue viewport rectangle
// shows the currently visible area. Tap to navigate.

import 'package:flutter/material.dart';

class CanvasMinimap extends StatelessWidget {
  const CanvasMinimap({
    super.key,
    required this.positions,
    required this.screenWidth,
    required this.screenHeight,
    required this.transformationController,
    required this.viewportSize,
  });

  final Map<String, Offset> positions;
  final double screenWidth;
  final double screenHeight;
  final TransformationController transformationController;
  final Size viewportSize;

  static const double _mapWidth = 180.0;
  static const double _mapHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const SizedBox.shrink();

    // Compute bounds of all screens
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final pos in positions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dx + screenWidth > maxX) maxX = pos.dx + screenWidth;
      if (pos.dy + screenHeight > maxY) maxY = pos.dy + screenHeight;
    }

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;
    if (contentWidth <= 0 || contentHeight <= 0) return const SizedBox.shrink();

    // Scale to fit minimap
    final scaleX = _mapWidth / contentWidth;
    final scaleY = _mapHeight / contentHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    return Positioned(
      right: 16,
      bottom: 16,
      child: GestureDetector(
        onTapDown: (details) {
          // Navigate canvas to tapped position on minimap
          final tapX = details.localPosition.dx / scale + minX;
          final tapY = details.localPosition.dy / scale + minY;
          final matrix = Matrix4.identity()
            ..translate(
                -tapX + viewportSize.width / 2,
                -tapY + viewportSize.height / 2);
          transformationController.value = matrix;
        },
        child: Container(
          width: _mapWidth,
          height: _mapHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: transformationController,
              builder: (context, matrix, _) {
                return CustomPaint(
                  painter: _MinimapPainter(
                    positions: positions,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    minX: minX,
                    minY: minY,
                    scale: scale,
                    transform: transformationController.value,
                    viewportSize: viewportSize,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.positions,
    required this.screenWidth,
    required this.screenHeight,
    required this.minX,
    required this.minY,
    required this.scale,
    required this.transform,
    required this.viewportSize,
  });

  final Map<String, Offset> positions;
  final double screenWidth;
  final double screenHeight;
  final double minX;
  final double minY;
  final double scale;
  final Matrix4 transform;
  final Size viewportSize;

  @override
  void paint(Canvas canvas, Size size) {
    final screenPaint = Paint()..color = const Color(0xFFCBD5E1);
    final screenBorder = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw screen rectangles
    for (final pos in positions.values) {
      final rect = Rect.fromLTWH(
        (pos.dx - minX) * scale,
        (pos.dy - minY) * scale,
        screenWidth * scale,
        screenHeight * scale,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          screenPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          screenBorder);
    }

    // Draw viewport rectangle
    final canvasScale = transform.getMaxScaleOnAxis();
    if (canvasScale <= 0) return;
    final tx = transform.getTranslation().x;
    final ty = transform.getTranslation().y;

    final vpLeft = (-tx / canvasScale - minX) * scale;
    final vpTop = (-ty / canvasScale - minY) * scale;
    final vpWidth = (viewportSize.width / canvasScale) * scale;
    final vpHeight = (viewportSize.height / canvasScale) * scale;

    final viewportPaint = Paint()
      ..color = const Color(0x333B82F6)
      ..style = PaintingStyle.fill;
    final viewportBorder = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final vpRect = Rect.fromLTWH(vpLeft, vpTop, vpWidth, vpHeight);
    canvas.drawRect(vpRect, viewportPaint);
    canvas.drawRect(vpRect, viewportBorder);
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) => true;
}
