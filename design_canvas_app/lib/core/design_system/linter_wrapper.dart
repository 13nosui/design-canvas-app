import 'package:flutter/material.dart';
import '../../core/design_system/theme_controller.dart';

class LinterWrapper extends StatelessWidget {
  final Widget child;
  final bool isCompliant;

  const LinterWrapper({
    super.key,
    required this.child,
    required this.isCompliant,
  });

  @override
  Widget build(BuildContext context) {
    // 祖先から直接依存せずに値をとるか...、変更時に即時反映させたいので dependOn... を使う
    // LintModeの切り替えでCanvasが再描画されるので、ここでも依存してよい
    final themeController = ThemeControllerProvider.of(context);
    final isLintMode = themeController.isLintMode;

    if (!isLintMode) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        
        // オーバーレイ
        Positioned.fill(
          child: CustomPaint(
            painter: isCompliant ? _CompliantPainter() : _NonCompliantPainter(),
          ),
        ),

        // バッジ
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCompliant ? Colors.green.shade800 : Colors.red.shade900,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Text(
              isCompliant ? '✨ Tokenized' : '⚠️ Magic Number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompliantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NonCompliantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 赤の透過オーバーレイ
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    // 斜線パターンの描画
    final stripePaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const spacing = 10.0;
    // -size.height から size.width まで線を引く
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }

    // 破線のボーダー (簡易的に実線を太く・赤くするだけなら drawRectでOK)
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // 破線を真面目に描画する
    final path = Path()..addRect(Offset.zero & size);
    _drawDashedPath(canvas, path, borderPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = 0.0;
    bool isDash = true;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final length = isDash ? dashWidth : dashSpace;
        if (isDash) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        isDash = !isDash;
      }
      distance = 0.0;
      isDash = true;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
