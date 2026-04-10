import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../../core/sandbox/inspectable.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/navigation/canvas_link.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../providers/canvas_virtual_pages.dart';
import 'canvas_editor_controller.dart';
import 'import_page.dart';
import 'canvas_inspector_client.dart';
import 'canvas_theme_exporter.dart';
import '../widgets/canvas_decor.dart';
import '../widgets/canvas_device_preview.dart';
import '../widgets/canvas_live_editor_panel.dart';
import '../widgets/sitemap_painter.dart';

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

class _DesignCanvasPageState extends State<DesignCanvasPage>
    with SingleTickerProviderStateMixin {
  PreviewMode _previewMode = PreviewMode.free;
  bool _showBackgroundDecor = true;
  bool _showConnectors = true;

  bool _isPanelOpen = false;
  double _inspectorWidth = 320.0;
  bool _isDragging = false;

  late final CanvasEditorController _editor;
  StreamSubscription<CanvasEditorEvent>? _editorEventSub;

  String? _selectedComponentId;
  bool _selectedComponentIsText = false;
  Offset? _selectedComponentPosition;
  OverlayEntry? _inlineEditorEntry;

  final CanvasLinkRegistry _linkRegistry = CanvasLinkRegistry();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FocusNode _canvasFocusNode = FocusNode();

  final double deviceSpacing = 64.0;

  DeviceSpec? get _singleDevice {
    switch (_previewMode) {
      case PreviewMode.free:
        return AppDevices.free;
      case PreviewMode.iphone15:
        return AppDevices.iphone15;
      case PreviewMode.pixel7:
        return AppDevices.pixel7;
      case PreviewMode.allDevices:
        return null;
    }
  }

  double get screenWidth {
    if (_previewMode == PreviewMode.allDevices) {
      final totalWidth = AppDevices.values
          .fold<double>(0, (sum, device) => sum + device.width);
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

  void _onCanvasPointerDown(PointerDownEvent event) {
    // 👇 キャンバスをクリックした瞬間、確実にフォーカスをキャンバスに取り戻す
    if (!_canvasFocusNode.hasFocus) {
      _canvasFocusNode.requestFocus();
    }

    // 💡 変更：手動フラグではなく、OSのキーボード状態を直接取得する
    final isModifierPressed = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (!isModifierPressed) {
      if (_inlineEditorEntry != null) _removeInlineEditor();
      return;
    }

    final hitTestResult = HitTestResult();
    WidgetsBinding.instance.hitTest(hitTestResult, event.position);

    bool hitInspectable = false;

    for (final entry in hitTestResult.path) {
      if (entry.target is RenderMetaData) {
        final metaData = (entry.target as RenderMetaData).metaData;
        if (metaData is InspectableData) {
          hitInspectable = true;
          setState(() {
            if (_selectedComponentId == metaData.id) {
              _selectedComponentId = null;
              _selectedComponentIsText = false;
              _selectedComponentPosition = null;
            } else {
              _selectedComponentId = metaData.id;
              _selectedComponentIsText = metaData.isText;
              final rb = entry.target as RenderBox;
              final transform = rb.getTransformTo(null);
              final bounds =
                  MatrixUtils.transformRect(transform, rb.paintBounds);
              _selectedComponentPosition = bounds.center;
            }
          });
          break;
        }
      }
    }

    if (!hitInspectable) {
      setState(() {
        _selectedComponentId = null;
        _selectedComponentIsText = false;
        _selectedComponentPosition = null;
        if (_inlineEditorEntry != null) _removeInlineEditor();
      });
    }
  }

  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _linkRegistry.addListener(_onLinksChanged);
    _editor = CanvasEditorController(client: HttpCanvasInspectorClient());
    _editor.addListener(_onEditorChanged);
    _editorEventSub = _editor.events.listen(_handleEditorEvent);
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

  void _onEditorChanged() {
    if (!mounted) return;
    // Inspector loading state / fields drive _isPanelOpen/the panel;
    // repaint whenever the controller reports a change.
    setState(() {
      _isPanelOpen = _isPanelOpen || _editor.inspectedFilePath != null;
    });
  }

  void _handleEditorEvent(CanvasEditorEvent event) {
    if (!mounted) return;
    final Color background = switch (event) {
      CanvasEditorSuccess() => Colors.green,
      CanvasEditorWarning() => Colors.orange,
      CanvasEditorError() => Colors.redAccent,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(event.message,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: background,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onLinksChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _linkRegistry.removeListener(_onLinksChanged);
    _linkRegistry.dispose();
    _editorEventSub?.cancel();
    _editor.removeListener(_onEditorChanged);
    _editor.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    if (_inlineEditorEntry != null) {
      _inlineEditorEntry!.remove();
      _inlineEditorEntry = null;
    }
    _canvasFocusNode.dispose();
    super.dispose();
  }

  void _removeInlineEditor() {
    if (_inlineEditorEntry != null) {
      _inlineEditorEntry!.remove();
      _inlineEditorEntry = null;
      FocusScope.of(context).requestFocus();
    }
  }

  void _showInlineEditor() {
    if (_selectedComponentId == null || _selectedComponentPosition == null)
      return;

    // Fallback: Currently we hardcode the Timeline text, ideally this comes from node backend or AST
    // ASTパース等で本来の文字列を取得するまでのプレースホルダー
    String currentText = 'New Text';

    final entry = OverlayEntry(builder: (context) {
      return Positioned(
          left: _selectedComponentPosition!.dx - 50,
          top: _selectedComponentPosition!.dy - 25,
          child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                    borderRadius: BorderRadius.circular(8)),
                child: TextField(
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                    ),
                    controller: TextEditingController(text: currentText),
                    onSubmitted: (newText) {
                      _editor.updateCodeText(
                          _selectedComponentId!, newText);
                      _removeInlineEditor();
                    }),
              )));
    });
    Overlay.of(context).insert(entry);
    _inlineEditorEntry = entry;
  }

  Map<String, AppRouteDef> _getFlatRoutes(List<AppRouteDef> routes) {
    final Map<String, AppRouteDef> map = {};
    for (var route in routes) {
      final key = route.name ?? route.path;
      map[key] = route;
      if (route.children.isNotEmpty) {
        map.addAll(_getFlatRoutes(route.children));
      }
    }
    return map;
  }

  Future<void> _loadInspector(String dartFilePath) async {
    // Eagerly open the panel — loadInspector can take a moment, but the
    // user expects immediate visual feedback when clicking a widget.
    setState(() => _isPanelOpen = true);
    await _editor.loadInspector(dartFilePath);
  }

  /// Static routes + any virtual (in-memory) routes from ImportPage.
  List<AppRouteDef> _allRoutes(BuildContext context) {
    final virtual = context.read<CanvasVirtualPages>().routes;
    return [...canvasRoutes, ...virtual];
  }

  Map<String, Offset> _calculatePositions(List<AppRouteDef> allRoutes) {
    final positions = <String, Offset>{};
    double currentX = 100.0;

    final flatRoutes = _getFlatRoutes(allRoutes);
    for (final key in flatRoutes.keys) {
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
    final viewportHeight =
        screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;

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

  void _onScreenDoubleTap(BuildContext ctx, String key, List<AppRouteDef> routes) {
    final route = _getFlatRoutes(routes)[key];
    if (route == null) return;
    final slug = CanvasVirtualPages.projectSlugFromPath(route.path);
    if (slug != null) {
      final payload = ctx.read<CanvasVirtualPages>().getPayload(slug);
      if (payload != null) {
        Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => ImportPage(
            encodedData: base64Url.encode(utf8.encode(json.encode(payload))),
          ),
        ));
        return;
      }
    }
    final filePath = 'lib/presentation/pages/${key.toLowerCase()}_page.dart';
    debugPrint('ANTIGRAVITY_OPEN_FILE: $filePath');
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('🖥️ Click-to-Code ($filePath)'),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildDevicePreview(
      DeviceSpec device, AppRouteDef? route, Widget content) {
    return CanvasDevicePreview(
      device: device,
      route: route,
      content: content,
      onLoadInspector: _loadInspector,
    );
  }

  Widget _buildLiveEditorPanel(BuildContext context) {
    return CanvasLiveEditorPanel(
      inspectorFilePath: _editor.inspectedFilePath,
      inspectorFields: _editor.inspectedFields,
      inspectorIsLoading: _editor.isInspectorLoading,
      selectedComponentId: _selectedComponentId,
      onUpdateStyleField: _editor.updateStyleField,
      onPromoteToken: _editor.promoteToken,
      showBackgroundDecor: _showBackgroundDecor,
      onToggleBackgroundDecor: (val) => setState(() => _showBackgroundDecor = val),
      onExportAndSaveCode: exportAndSaveCanvasTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the virtual-pages notifier so the canvas rebuilds when
    // ImportPage pushes new pages via "キャンバスに送る".
    context.watch<CanvasVirtualPages>();
    final allRoutes = _allRoutes(context);
    final positions = _calculatePositions(allRoutes);
    final themeController = ThemeControllerProvider.of(context);
    final primary = themeController.primaryColor;
    final complement = HSLColor.fromColor(primary)
        .withHue((HSLColor.fromColor(primary).hue + 180) % 360)
        .toColor();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Design Canvas'),
        elevation: 1,
        actions: [
          Builder(builder: (context) {
            final themeController = ThemeControllerProvider.of(context);
            return IconButton(
              icon: Icon(themeController.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                themeController.updateTheme(
                    mode: themeController.themeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light);
              },
            );
          }),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(
                    value: PreviewMode.free,
                    label: Text('Free', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.iphone15,
                    label: Text('iPhone 15', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.pixel7,
                    label: Text('Pixel 7', style: TextStyle(fontSize: 12))),
                ButtonSegment(
                    value: PreviewMode.allDevices,
                    label: Text('All Devices',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold))),
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
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Toggle Properties Panel',
              onPressed: () {
                setState(() {
                  _isPanelOpen = !_isPanelOpen;
                });
              },
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: _canvasFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.keyT) {
                  if (_selectedComponentId != null &&
                      _selectedComponentIsText &&
                      _inlineEditorEntry == null) {
                    _showInlineEditor();
                    return KeyEventResult.handled;
                  }
                }

                if (event is KeyDownEvent &&
                    HardwareKeyboard.instance.isShiftPressed) {
                  if (event.logicalKey == LogicalKeyboardKey.keyP) {
                    if (_selectedComponentId != null &&
                        _inlineEditorEntry == null) {
                      _editor.wrapComponent(_selectedComponentId, 'Padding');
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
                    if (_selectedComponentId != null &&
                        _inlineEditorEntry == null) {
                      _editor.wrapComponent(_selectedComponentId, 'Center');
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
                    if (_selectedComponentId != null &&
                        _inlineEditorEntry == null) {
                      _editor.unwrapComponent(_selectedComponentId);
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
                    if (_selectedComponentId != null &&
                        _inlineEditorEntry == null) {
                      _editor.insertComponent(_selectedComponentId);
                      return KeyEventResult.handled;
                    }
                  }
                }

                if (event is KeyDownEvent &&
                    (HardwareKeyboard.instance.isMetaPressed ||
                        HardwareKeyboard.instance.isControlPressed)) {
                  if (event.logicalKey == LogicalKeyboardKey.keyD) {
                    if (_selectedComponentId != null &&
                        _inlineEditorEntry == null) {
                      _editor.duplicateComponent(_selectedComponentId);
                      return KeyEventResult.handled;
                    }
                  }
                }

                return KeyEventResult.ignored;
              },
              child: Listener(
                onPointerDown: _onCanvasPointerDown,
                behavior: HitTestBehavior.translucent,
                child: CanvasState(
                  selectedComponentId: _selectedComponentId,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.05,
                    maxScale: 3.0,
                    constrained: false,
                    child: SizedBox(
                      width: 8000,
                      height: 3000,
                      child: InheritedRegistry(
                        registry: _linkRegistry,
                        canvasKey: _canvasKey,
                        child: Stack(
                          key: _canvasKey,
                          children: [
                            Positioned.fill(
                              child: Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            if (_showBackgroundDecor)
                              Positioned.fill(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: -200,
                                      top: 100,
                                      child: buildCanvasDecorCircle(
                                          primary.withOpacity(0.4), 1200),
                                    ),
                                    Positioned(
                                      left: 1000,
                                      top: -400,
                                      child: buildCanvasDecorCircle(
                                          complement.withOpacity(0.3), 1400),
                                    ),
                                    Positioned(
                                      left: 2800,
                                      top: 500,
                                      child: buildCanvasDecorCircle(
                                          Colors.pinkAccent.withOpacity(0.3),
                                          1000),
                                    ),
                                    Positioned(
                                      left: 4200,
                                      top: -100,
                                      child: buildCanvasDecorCircle(
                                          Colors.cyanAccent.withOpacity(0.3),
                                          1500),
                                    ),
                                    Positioned(
                                      left: 6000,
                                      top: 600,
                                      child: buildCanvasDecorCircle(
                                          primary.withOpacity(0.35), 1100),
                                    ),
                                  ],
                                ),
                              ),
                            if (_showConnectors)
                              Positioned.fill(
                                child: Builder(builder: (context) {
                                  final sitemapDefinition =
                                      <String, List<String>>{};
                                  final flatRoutes =
                                      _getFlatRoutes(allRoutes);
                                  for (final r in flatRoutes.values) {
                                    final targets = <String>[];
                                    targets.addAll(r.children
                                        .map((c) => c.name ?? c.path));
                                    // linksToの中に含まれるpathやnameを探索して正しいキー(name ?? path)を取得する
                                    for (final link in r.linksTo) {
                                      final match = flatRoutes.values
                                          .where((def) =>
                                              def.path == link ||
                                              def.name == link)
                                          .firstOrNull;
                                      if (match != null) {
                                        targets.add(match.name ?? match.path);
                                      } else {
                                        targets.add(link);
                                      }
                                    }
                                    sitemapDefinition[r.name ?? r.path] =
                                        targets;
                                  }
                                  return CustomPaint(
                                    painter: SitemapPainter(
                                      sitemap: sitemapDefinition,
                                      positions: positions,
                                      dynamicLinks: _linkRegistry.links,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      lineColor: context.appColors.primary,
                                    ),
                                  );
                                }),
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
                                  onDoubleTap: () => _onScreenDoubleTap(
                                      context, entry.key, allRoutes),
                                  child: _previewMode == PreviewMode.allDevices
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: AppDevices.values
                                              .asMap()
                                              .entries
                                              .map((devEntry) {
                                            final idx = devEntry.key;
                                            final dev = devEntry.value;
                                            final flatRoutes =
                                                _getFlatRoutes(allRoutes);
                                            final route = flatRoutes[entry.key];
                                            final content =
                                                CurrentRouteProvider(
                                              routePath: route?.name ??
                                                  route?.path ??
                                                  '',
                                              child: route?.builder(context) ??
                                                  const Center(
                                                      child: Text('Not Found')),
                                            );

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                right: idx <
                                                        AppDevices
                                                                .values.length -
                                                            1
                                                    ? deviceSpacing
                                                    : 0,
                                              ),
                                              child: _buildDevicePreview(
                                                  dev, route, content),
                                            );
                                          }).toList(),
                                        )
                                      : (() {
                                          final flatRoutes =
                                              _getFlatRoutes(allRoutes);
                                          final route = flatRoutes[entry.key];
                                          final content = CurrentRouteProvider(
                                            routePath: route?.name ??
                                                route?.path ??
                                                '',
                                            child: route?.builder(context) ??
                                                const Center(
                                                    child: Text('Not Found')),
                                          );
                                          return _buildDevicePreview(
                                            _singleDevice!,
                                            route,
                                            content,
                                          );
                                        })(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ), // end Expanded

          // --- Resize Handle (Figma Like) ---
          if (_isPanelOpen)
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) {
                  setState(() => _isDragging = true);
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _inspectorWidth -= details.delta.dx;
                    final maxWidth = MediaQuery.of(context).size.width / 2;
                    _inspectorWidth = _inspectorWidth.clamp(200.0, maxWidth);
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                child: Container(
                  width: 4,
                  color: Colors.transparent,
                ),
              ),
            ),

          // --- Properties Panel ---
          AnimatedContainer(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isPanelOpen ? _inspectorWidth : 0.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color:
                      Colors.grey.withOpacity(0.2), // Figma-like subtle border
                  width: 1,
                ),
              ),
              boxShadow: [
                if (_isPanelOpen)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  )
              ],
            ),
            child: ClipRect(
              // 横幅が0になっても中身がはみ出さないようにClip
              // --- ここから修正 ---
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: _inspectorWidth,
                maxWidth: _inspectorWidth,
                child: Theme(
                  data: ThemeData(
                    useMaterial3: true,
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.blueGrey,
                        brightness: Brightness.light),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(fontSize: 14),
                      bodyMedium: TextStyle(fontSize: 13),
                      bodySmall: TextStyle(fontSize: 11),
                      labelLarge:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  child: Builder(
                    builder: (editorContext) =>
                        _buildLiveEditorPanel(editorContext),
                  ),
                ),
              ),
              // --- ここまで修正 ---
            ),
          ),
        ], // end Row children
      ), // end Row
    ); // end Scaffold
  }
}

