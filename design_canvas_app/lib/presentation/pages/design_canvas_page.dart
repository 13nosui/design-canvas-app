import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/navigation/sitemap_definition.dart';
import '../../core/navigation/sitemap_widgets.g.dart';

enum PreviewMode {
  free,
  iphone15,
  pixel7,
  allDevices,
}

class DesignCanvasPage extends StatefulWidget {
  const DesignCanvasPage({super.key});

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage> with SingleTickerProviderStateMixin {
  PreviewMode _previewMode = PreviewMode.free;

  // デバイス間の間隔（Allモード時の横並びの余白）
  final double deviceSpacing = 64.0;

  DeviceSpec? get _singleDevice {
    switch (_previewMode) {
      case PreviewMode.free: return AppDevices.free;
      case PreviewMode.iphone15: return AppDevices.iphone15;
      case PreviewMode.pixel7: return AppDevices.pixel7;
      case PreviewMode.allDevices: return null;
    }
  }

  // 1つのノード（画面群）の全体の幅を計算
  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth = AppDevices.values.fold<double>(0, (sum, device) => sum + device.width);
      final spacingWidth = deviceSpacing * (AppDevices.values.length - 1);
      return totalWidth + spacingWidth;
    }
    return _singleDevice!.width;
  }

  // 1つのノード（画面群）の全体の高さを計算
  double get screenHeight {
    if (_previewMode == PreviewMode.allDevices) {
      return AppDevices.values.map((d) => d.height).reduce((a, b) => max(a, b));
    }
    return _singleDevice!.height;
  }

  // サイトマップ描画時の、ノード間の余白（xSpacing）
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
      duration: const Duration(milliseconds: 500),
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

  // 各画面グループの左上座標を計算
  Map<String, Offset> _calculatePositions() {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    
    // シンプルに左から右へノードを並べるロジック
    for (final key in sitemapDefinition.keys) {
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  // 該当の座標へアニメーションしてズーム移動する
  void _zoomToScreen(Offset targetPosition) {
    final screenSize = MediaQuery.of(context).size;
    
    // Allモードの場合は横幅が大きいので、少し引きで（縮小して）表示する
    double targetScale = 1.0;
    if (_previewMode == PreviewMode.allDevices) {
      // 少し縮小しておく（最大でも画面幅にフィットするように概算）
      targetScale = min(1.0, screenSize.width / (screenWidth + 100));
    }

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

  // 個別のデバイスプレビューコンテナ（ベゼルと画面の中身）を描画
  Widget _buildDevicePreview(DeviceSpec device, Widget content) {
    return Container(
      width: device.width,
      height: device.height,
      decoration: BoxDecoration(
        color: Colors.black, // ベゼルの色
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
          (device.borderRadius - device.bezelWidth).clamp(0.0, double.infinity),
        ),
        child: Container(
          color: Colors.white,
          child: AbsorbPointer(
            child: content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Canvas (Sitemap)'),
        elevation: 1,
        actions: [
          // デバイス切り替えツールバー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(value: PreviewMode.free, label: Text('Free', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.iphone15, label: Text('iPhone 15', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.pixel7, label: Text('Pixel 7', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: PreviewMode.allDevices, label: Text('All Devices', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
              selected: {_previewMode},
              onSelectionChanged: (Set<PreviewMode> newSelection) {
                setState(() {
                  _previewMode = newSelection.first;
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
          width: 8000,
          height: 3000,
          child: Stack(
            children: [
              // 背景
              Positioned.fill(
                child: Container(
                  color: Colors.grey[100],
                ),
              ),
              // 第一層：線を描画
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
              // 第二層：画面（ノード）を配置
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
                    // モードに応じて中身を単一か複数並列か分岐
                    child: _previewMode == PreviewMode.allDevices
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center, // 横並び時に中央揃え
                            children: AppDevices.values.asMap().entries.map((devEntry) {
                              final idx = devEntry.key;
                              final dev = devEntry.value;
                              final content = generatedScreenWidgets[entry.key] ?? const Center(child: Text('Not Found'));
                              
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: idx < AppDevices.values.length - 1 ? deviceSpacing : 0,
                                ),
                                child: _buildDevicePreview(dev, content),
                              );
                            }).toList(),
                          )
                        : _buildDevicePreview(
                            _singleDevice!,
                            generatedScreenWidgets[entry.key] ?? const Center(child: Text('Not Found')),
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
