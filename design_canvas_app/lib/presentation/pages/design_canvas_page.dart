import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/navigation/sitemap_definition.dart';
import '../../core/navigation/sitemap_widgets.g.dart';

class DesignCanvasPage extends StatefulWidget {
  const DesignCanvasPage({super.key});

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage> with SingleTickerProviderStateMixin {
  // 画面のサイズ設定（iPhone等に近い比率で縮小表示）
  final double screenWidth = 250;
  final double screenHeight = 500;
  // 画面間の横の間隔
  final double xSpacing = 150;

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
      positions[key] = Offset(currentX, 200.0);
      currentX += screenWidth + xSpacing;
    }
    return positions;
  }

  // 該当の座標へアニメーションしてズーム移動する
  void _zoomToScreen(Offset targetPosition) {
    // Scaffoldのボディサイズ（Viewport全体）と扱う
    final screenSize = MediaQuery.of(context).size;
    
    // 原寸大（1.0倍）へズーム
    const targetScale = 1.0;

    // Target画面の中心座標（キャンバス上）
    final screenCenterX = targetPosition.dx + (screenWidth / 2);
    final screenCenterY = targetPosition.dy + (screenHeight / 2);

    // Viewportとしての中心座標（表示領域）
    // SafeAreaやAppBarの影響である程度ズレるため概算（Scaffoldのbody幅を利用）
    final viewportWidth = screenSize.width;
    final viewportHeight = screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;

    final viewportCenterX = viewportWidth / 2;
    final viewportCenterY = viewportHeight / 2;

    // 行列の平行移動成分を計算（スケール適用後の位置に合わせるため targetScale をかける）
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
      curve: Curves.easeInOutBack, // リズミカルなアニメーション
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitemap Canvas'),
        elevation: 0,
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 2.0,
        constrained: false,
        child: SizedBox(
          width: 3000,
          height: 3000,
          child: Stack(
            children: [
              // 背景となるキャンバスのベース
              Positioned.fill(
                child: Container(
                  color: Colors.grey[100],
                ),
              ),
              // 第一層：画面同士を結ぶ線を描画
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
              // 第二層：各画面のWidgetを配置
              for (final entry in positions.entries)
                Positioned(
                  left: entry.value.dx,
                  top: entry.value.dy,
                  width: screenWidth,
                  height: screenHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GestureDetector(
                      // タップを確実に拾うための指定
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // 画面中心にズーム移動
                        _zoomToScreen(entry.value);
                      },
                      onDoubleTap: () {
                        // Click-to-Code のプレビュー雛形
                        // ファイルパスの算出（仮）例：home -> lib/presentation/pages/home_page.dart
                        final snakeCaseKey = entry.key.toLowerCase();
                        final filePath = 'lib/presentation/pages/${snakeCaseKey}_page.dart';
                        
                        debugPrint('ANTIGRAVITY_OPEN_FILE: $filePath');
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🖥️ Click-to-Code ($filePath)\n（コンソールを確認してください）'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      // 画面内の中身のボタン等が押されないようにジェスチャーを吸収する
                      child: AbsorbPointer(
                        child: generatedScreenWidgets[entry.key] ?? const Center(child: Text('Not Found')),
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

// 画面間を線で結ぶカスタムペインター
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

      // 画面の右端中央を出発点とする
      final startPoint = Offset(fromPos.dx + screenWidth, fromPos.dy + screenHeight / 2);

      for (final toNode in sitemap[fromNode]!) {
        final toPos = positions[toNode];
        if (toPos == null) continue;

        // 次の画面の左端中央を到着点とする
        final endPoint = Offset(toPos.dx, toPos.dy + screenHeight / 2);

        // ベジェ曲線を使って柔らかい線を引く
        final path = Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..cubicTo(
            startPoint.dx + 50, startPoint.dy,
            endPoint.dx - 50, endPoint.dy,
            endPoint.dx, endPoint.dy,
          );

        canvas.drawPath(path, paint);
        
        // 到着点に矢印風の円を描画
        canvas.drawCircle(endPoint, 6.0, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SitemapPainter oldDelegate) {
    return false; // 今回は静的データのため再描画不要
  }
}
