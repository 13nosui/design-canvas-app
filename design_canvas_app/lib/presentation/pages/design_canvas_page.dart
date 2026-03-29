import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
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

  final double deviceSpacing = 64.0;

  DeviceSpec? get _singleDevice {
    switch (_previewMode) {
      case PreviewMode.free: return AppDevices.free;
      case PreviewMode.iphone15: return AppDevices.iphone15;
      case PreviewMode.pixel7: return AppDevices.pixel7;
      case PreviewMode.allDevices: return null;
    }
  }

  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth = AppDevices.values.fold<double>(0, (sum, device) => sum + device.width);
      final spacingWidth = deviceSpacing * (AppDevices.values.length - 1);
      return totalWidth + spacingWidth;
    }
    return _singleDevice!.width;
  }

  double get screenHeight {
    if (_previewMode == PreviewMode.allDevices) {
      return AppDevices.values.map((d) => d.height).reduce((a, b) => max(a, b));
    }
    return _singleDevice!.height;
  }

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

  Map<String, Offset> _calculatePositions() {
    final positions = <String, Offset>{};
    double currentX = 100.0;
    
    for (final key in sitemapDefinition.keys) {
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  void _zoomToScreen(Offset targetPosition) {
    final screenSize = MediaQuery.of(context).size;
    
    double targetScale = 1.0;
    if (_previewMode == PreviewMode.allDevices) {
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

  Widget _buildDevicePreview(DeviceSpec device, Widget content) {
    return Container(
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

  // 右側に引き出される「ライブ・スタイル・エディタ」の構築
  Widget _buildLiveEditorDrawer(BuildContext context) {
    // ThemeControllerProviderの値を監視して即時再描画
    final themeController = ThemeControllerProvider.of(context);
    
    // Flutter標準の18色のプライマリーカラー一覧
    final List<Color> paletteColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.blueGrey, Colors.grey,
    ];

    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Live Style Editor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            
            // --- Color Picker ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Primary Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: paletteColors.map((color) {
                  final isSelected = themeController.primaryColor.value == color.value;
                  return GestureDetector(
                    onTap: () => themeController.updateTheme(primary: color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black87, width: 3) : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            
            // --- Spacing Slider ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text('Spacing Base Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // 現在の値から割り出したSMLの一覧を表示
              child: Text(
                'Current Base: ${themeController.spacingBase.toStringAsFixed(1)}px\n\n'
                '• S (Small): ${themeController.spacingBase.toStringAsFixed(1)}px\n'
                '• M (Medium): ${(themeController.spacingBase * 2).toStringAsFixed(1)}px\n'
                '• L (Large): ${(themeController.spacingBase * 3).toStringAsFixed(1)}px',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeController.spacingBase,
              min: 4.0,
              max: 24.0,
              divisions: 20,
              label: '${themeController.spacingBase.toStringAsFixed(1)} px',
              onChanged: (val) {
                // スライダーを動かした瞬間にThemeControllerに通知が行き、即座にリビルド連鎖が起きる
                themeController.updateTheme(spacing: val);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Canvas'),
        elevation: 1,
        actions: [
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
          // スライダパネル等を開くボタン
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Live Style Editor',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: _buildLiveEditorDrawer(context), // 右側のサイドパネル
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
                    child: _previewMode == PreviewMode.allDevices
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: AppDevices.values.asMap().entries.map((devEntry) {
                              final idx = devEntry.key;
                              final dev = devEntry.value;
                              final content = generatedScreenBuilders[entry.key]?.call(context) ?? const Center(child: Text('Not Found'));
                              
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
                            generatedScreenBuilders[entry.key]?.call(context) ?? const Center(child: Text('Not Found')),
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
           oldDelegate.positions != positions ||
           oldDelegate.lineColor != lineColor;
  }
}
