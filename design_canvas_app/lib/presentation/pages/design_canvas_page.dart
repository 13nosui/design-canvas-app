import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/navigation/sitemap_definition.dart';
import '../../core/navigation/sitemap_widgets.g.dart';

class DesignCanvasPage extends StatefulWidget {
  const DesignCanvasPage({super.key});

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage> with SingleTickerProviderStateMixin {
  DeviceSpec _selectedDevice = AppDevices.free;

  // デバイスの定義からサイズを取得
  double get screenWidth => _selectedDevice.width;
  double get screenHeight => _selectedDevice.height;

  // 画面間の横の間隔
  final double xSpacing = 200;

  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 各画面の座標を計算
  Map<String, Offset> _calculatePositions() {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    
    // シンプルに左から右へ並べるロジック
    for (final key in sitemapDefinition.keys) {
      // 少し下に余白を取る
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  // 該当の座標へアニメーションしてズーム移動する
  void _zoomToScreen(Offset targetPosition) {
    final screenSize = MediaQuery.of(context).size;
    const targetScale = 1.0;

    final screenCenterX = targetPosition.dx + (screenWidth / 2);
    final screenCenterY = targetPosition.dy + (screenHeight / 2);

    final viewportWidth = screenSize.width;
    final viewportHeight = screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;

    final viewportCenterX = viewportWidth / 2;
    final viewportCenterY = viewportHeight / 2;

    final targetX = viewportCenterX - (screenCenterX * targetScale);
    final targetY = viewportCenterY - (screenCenterY * targetScale);

    final targetMatrix = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(targetScale);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitemap Canvas'),
        elevation: 1,
        actions: [
          // デバイス切り替えツールバー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<DeviceSpec>(
              segments: AppDevices.values.map((device) {
                return ButtonSegment<DeviceSpec>(
                  value: device,
                  label: Text(device.name, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              selected: {_selectedDevice},
              onSelectionChanged: (Set<DeviceSpec> newSelection) {
                setState(() {
                  _selectedDevice = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.05,
        maxScale: 3.0,
        constrained: false,
        child: SizedBox(
          width: 5000,
          height: 3000,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.grey[100],
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: SitemapPainter(
                    sitemap: sitemapDefinition,
                    positions: positions,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    lineColor: context.appColors.primary,
                  ),
                ),
              ),
              for (final entry in positions.entries)
                Positioned(
                  left: entry.value.dx,
                  top: entry.value.dy,
                  width: screenWidth,
                  height: screenHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _zoomToScreen(entry.value),
                    onDoubleTap: () {
                      final snakeCaseKey = entry.key.toLowerCase();
                      final filePath = 'lib/presentation/pages/${snakeCaseKey}_page.dart';
                      debugPrint('ANTIGRAVITY_OPEN_FILE: $filePath');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🖥️ Click-to-Code ($filePath)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    // ベゼルの描画
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black, // ベゼルの色
                        borderRadius: BorderRadius.circular(_selectedDevice.borderRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 30,
                            offset: Offset(0, 15),
                          )
                        ],
                      ),
                      padding: EdgeInsets.all(_selectedDevice.bezelWidth),
                      child: ClipRRect(
                        // ベゼル分だけ内側の角丸を小さくする
                        borderRadius: BorderRadius.circular(
                          (_selectedDevice.borderRadius - _selectedDevice.bezelWidth).clamp(0.0, double.infinity),
                        ),
                        child: Container(
                          color: Colors.white,
                          child: AbsorbPointer(
                            child: generatedScreenWidgets[entry.key] ?? const Center(child: Text('Not Found')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SitemapPainter extends CustomPainter {
  final Map<String, List<String>> sitemap;
  final Map<String, Offset> positions;
  final double screenWidth;
  final double screenHeight;
  final Color lineColor;

  SitemapPainter({
    required this.sitemap,
    required this.positions,
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

    for (final fromNode in sitemap.keys) {
      final fromPos = positions[fromNode];
      if (fromPos == null) continue;

      final startPoint = Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

      for (final toNode in sitemap[fromNode]!) {
        final toPos = positions[toNode];
        if (toPos == null) continue;

        final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);

        final path = Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..cubicTo(
            startPoint.dx + 50, startPoint.dy,
            endPoint.dx - 50, endPoint.dy,
            endPoint.dx, endPoint.dy,
          );

        canvas.drawPath(path, paint);
        canvas.drawCircle(endPoint, 6.0, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SitemapPainter oldDelegate) {
    return oldDelegate.screenWidth != screenWidth ||
           oldDelegate.screenHeight != screenHeight ||
           oldDelegate.sitemap != sitemap ||
           oldDelegate.positions != positions;
  }
}
