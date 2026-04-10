import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../core/sandbox/inspectable.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/device_specs.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/navigation/canvas_link.dart';
import '../../app/router.dart';
import '../providers/canvas_layout_controller.dart';
import '../providers/canvas_virtual_pages.dart';
import '../providers/project_list_controller.dart';
import '../providers/widget_palette_controller.dart';
import '../widgets/canvas_decor.dart';
import '../widgets/canvas_device_preview.dart';
import '../widgets/canvas_live_editor_panel.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/project_list_bar.dart';
import '../widgets/sitemap_painter.dart';
import '../widgets/widget_palette_sidebar.dart';
import 'canvas_editor_controller.dart';
import 'canvas_inspector_client.dart';
import 'canvas_theme_exporter.dart';
import 'import_page.dart';

class DesignCanvasPage extends StatefulWidget {
  const DesignCanvasPage({super.key});

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage>
    with SingleTickerProviderStateMixin {
  late final CanvasEditorController _editor;
  StreamSubscription<CanvasEditorEvent>? _editorEventSub;

  OverlayEntry? _inlineEditorEntry;

  final CanvasLinkRegistry _linkRegistry = CanvasLinkRegistry();
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _canvasFocusNode = FocusNode();

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
    final layout = context.read<CanvasLayoutController>();
    if (_editor.inspectedFilePath != null) layout.openPanel();
    setState(() {});
  }

  void _handleEditorEvent(CanvasEditorEvent event) {
    if (!mounted) return;
    final Color bg = switch (event) {
      CanvasEditorSuccess() => Colors.green,
      CanvasEditorWarning() => Colors.orange,
      CanvasEditorError() => Colors.redAccent,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(event.message, style: const TextStyle(color: Colors.white)),
      backgroundColor: bg,
      duration: const Duration(seconds: 3),
    ));
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

  // ── Inline text editor ──────────────────────────────────────

  void _removeInlineEditor() {
    if (_inlineEditorEntry != null) {
      _inlineEditorEntry!.remove();
      _inlineEditorEntry = null;
      FocusScope.of(context).requestFocus();
    }
  }

  void _showInlineEditor(CanvasLayoutController layout) {
    final id = layout.selectedComponentId;
    final pos = layout.selectedComponentPosition;
    if (id == null || pos == null) return;

    final entry = OverlayEntry(builder: (ctx) {
      return Positioned(
        left: pos.dx - 50,
        top: pos.dy - 25,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10)
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: Theme.of(ctx).colorScheme.surface,
                filled: true,
              ),
              controller: TextEditingController(text: 'New Text'),
              onSubmitted: (newText) {
                _editor.updateCodeText(id, newText);
                _removeInlineEditor();
              },
            ),
          ),
        ),
      );
    });
    Overlay.of(context).insert(entry);
    _inlineEditorEntry = entry;
  }

  // ── Cmd+Click hit testing ───────────────────────────────────

  void _onCanvasPointerDown(PointerDownEvent event) {
    if (!_canvasFocusNode.hasFocus) _canvasFocusNode.requestFocus();

    final isModifier = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!isModifier) {
      if (_inlineEditorEntry != null) _removeInlineEditor();
      return;
    }

    final layout = context.read<CanvasLayoutController>();
    final hitTestResult = HitTestResult();
    WidgetsBinding.instance.hitTest(hitTestResult, event.position);

    for (final entry in hitTestResult.path) {
      if (entry.target is RenderMetaData) {
        final metaData = (entry.target as RenderMetaData).metaData;
        if (metaData is InspectableData) {
          final rb = entry.target as RenderBox;
          final transform = rb.getTransformTo(null);
          final bounds = MatrixUtils.transformRect(transform, rb.paintBounds);
          layout.selectComponent(metaData.id, metaData.isText, bounds.center);
          return;
        }
      }
    }
    layout.clearSelection();
    if (_inlineEditorEntry != null) _removeInlineEditor();
  }

  // ── Keyboard shortcuts ──────────────────────────────────────

  KeyEventResult _handleKeyEvent(
      FocusNode node, KeyEvent event, CanvasLayoutController layout) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final id = layout.selectedComponentId;
    if (id == null || _inlineEditorEntry != null) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyT &&
        layout.selectedComponentIsText) {
      _showInlineEditor(layout);
      return KeyEventResult.handled;
    }

    if (HardwareKeyboard.instance.isShiftPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyP:
          _editor.wrapComponent(id, 'Padding');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyC:
          _editor.wrapComponent(id, 'Center');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyU:
          _editor.unwrapComponent(id);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyN:
          _editor.insertComponent(id);
          return KeyEventResult.handled;
        default:
          break;
      }
    }

    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _editor.duplicateComponent(id);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ── Navigation helpers ──────────────────────────────────────

  void _zoomToScreen(CanvasLayoutController layout, Offset target) {
    final screenSize = MediaQuery.of(context).size;
    double targetScale = 1.0;
    if (layout.previewMode == PreviewMode.allDevices) {
      targetScale = min(1.0, screenSize.width / (layout.screenWidth + 100));
    }
    final cx = target.dx + layout.screenWidth / 2;
    final cy = target.dy + layout.screenHeight / 2;
    final vw = screenSize.width;
    final vh = screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;
    final tx = vw / 2 - cx * targetScale;
    final ty = vh / 2 - cy * targetScale;
    final targetMatrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale);
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutBack));
    _animationController.forward(from: 0.0);
  }

  void _onScreenDoubleTap(BuildContext ctx, String key, List<AppRouteDef> routes) {
    final route = CanvasLayoutController.getFlatRoutes(routes)[key];
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

  Future<void> _loadInspector(String dartFilePath) async {
    context.read<CanvasLayoutController>().openPanel();
    await _editor.loadInspector(dartFilePath);
  }

  // ── Route helpers ───────────────────────────────────────────

  List<AppRouteDef> _allRoutes(BuildContext context) {
    final virtual = context.read<CanvasVirtualPages>().routes;
    final projectFilter = context.read<ProjectListController>().selectedSlug;
    if (projectFilter == null) return [...canvasRoutes, ...virtual];
    // Filter virtual routes to selected project only
    final filtered = virtual
        .where((r) => r.path.startsWith('/virtual/$projectFilter/'))
        .toList();
    return [...canvasRoutes, ...filtered];
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<CanvasVirtualPages>();
    context.watch<ProjectListController>();
    final layout = context.watch<CanvasLayoutController>();
    final allRoutes = _allRoutes(context);
    final positions = layout.calculatePositions(allRoutes);
    final themeController = ThemeControllerProvider.of(context);
    final primary = themeController.primaryColor;
    final complement = HSLColor.fromColor(primary)
        .withHue((HSLColor.fromColor(primary).hue + 180) % 360)
        .toColor();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // ── Project list bar ──
          const ProjectListBar(),
          // ── Toolbar ──
          _buildToolbar(context, layout, themeController),
          // ── Canvas + Panel ──
          Expanded(child: _buildCanvasRow(
              context, layout, allRoutes, positions, primary, complement)),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, CanvasLayoutController layout,
      ThemeControllerProvider themeController) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Widget palette toggle
          IconButton(
            icon: Icon(
              context.watch<WidgetPaletteController>().isOpen
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
              size: 18,
            ),
            tooltip: 'Widget Palette',
            onPressed: context.read<WidgetPaletteController>().toggleSidebar,
          ),
          const Text('Design Canvas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          // Dark mode toggle
          IconButton(
            icon: Icon(themeController.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
                size: 18),
            tooltip: 'Toggle Dark Mode',
            onPressed: () => themeController.updateTheme(
                mode: themeController.themeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light),
          ),
          // Device mode
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(value: PreviewMode.free,
                    label: Text('Free', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: PreviewMode.iphone15,
                    label: Text('iPhone', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: PreviewMode.pixel7,
                    label: Text('Pixel', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: PreviewMode.allDevices,
                    label: Text('All', style: TextStyle(fontSize: 11))),
              ],
              selected: {layout.previewMode},
              onSelectionChanged: (s) => layout.setPreviewMode(s.first),
            ),
          ),
          // Properties panel toggle
          IconButton(
            icon: const Icon(Icons.palette_outlined, size: 18),
            tooltip: 'Toggle Properties Panel',
            onPressed: layout.togglePanel,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasRow(
      BuildContext context,
      CanvasLayoutController layout,
      List<AppRouteDef> allRoutes,
      Map<String, Offset> positions,
      Color primary,
      Color complement) {
    final palette = context.watch<WidgetPaletteController>();
    return Row(
      children: [
        if (palette.isOpen) const WidgetPaletteSidebar(),
        Expanded(
          child: Focus(
            focusNode: _canvasFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) =>
                _handleKeyEvent(node, event, layout),
            child: Listener(
              onPointerDown: _onCanvasPointerDown,
              behavior: HitTestBehavior.translucent,
              child: CanvasState(
                selectedComponentId: layout.selectedComponentId,
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
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                          ),
                          if (layout.showBackgroundDecor)
                            _buildDecor(primary, complement),
                          if (layout.showConnectors)
                            _buildConnectors(allRoutes, positions, layout),
                          ..._buildScreenCards(
                              context, layout, allRoutes, positions),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (layout.isPanelOpen) _buildResizeHandle(layout),
        _buildPropertiesPanel(context, layout),
      ],
    );
  }

  Widget _buildDecor(Color primary, Color complement) {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(left: -200, top: 100,
            child: buildCanvasDecorCircle(primary.withOpacity(0.4), 1200)),
        Positioned(left: 1000, top: -400,
            child: buildCanvasDecorCircle(complement.withOpacity(0.3), 1400)),
        Positioned(left: 2800, top: 500,
            child: buildCanvasDecorCircle(Colors.pinkAccent.withOpacity(0.3), 1000)),
        Positioned(left: 4200, top: -100,
            child: buildCanvasDecorCircle(Colors.cyanAccent.withOpacity(0.3), 1500)),
        Positioned(left: 6000, top: 600,
            child: buildCanvasDecorCircle(primary.withOpacity(0.35), 1100)),
      ]),
    );
  }

  Widget _buildConnectors(List<AppRouteDef> allRoutes,
      Map<String, Offset> positions, CanvasLayoutController layout) {
    return Positioned.fill(
      child: Builder(builder: (context) {
        final flat = CanvasLayoutController.getFlatRoutes(allRoutes);
        final sitemap = <String, List<String>>{};
        for (final r in flat.values) {
          final targets = <String>[
            ...r.children.map((c) => c.name ?? c.path),
          ];
          for (final link in r.linksTo) {
            final match = flat.values
                .where((d) => d.path == link || d.name == link)
                .firstOrNull;
            targets.add(match != null ? (match.name ?? match.path) : link);
          }
          sitemap[r.name ?? r.path] = targets;
        }
        return CustomPaint(
          painter: SitemapPainter(
            sitemap: sitemap,
            positions: positions,
            dynamicLinks: _linkRegistry.links,
            screenWidth: layout.screenWidth,
            screenHeight: layout.screenHeight,
            lineColor: context.appColors.primary,
          ),
        );
      }),
    );
  }

  List<Widget> _buildScreenCards(BuildContext context,
      CanvasLayoutController layout, List<AppRouteDef> allRoutes,
      Map<String, Offset> positions) {
    final flat = CanvasLayoutController.getFlatRoutes(allRoutes);
    return [
      for (final entry in positions.entries)
        Positioned(
          left: entry.value.dx,
          top: entry.value.dy,
          width: layout.screenWidth,
          height: layout.screenHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _zoomToScreen(layout, entry.value),
            onDoubleTap: () =>
                _onScreenDoubleTap(context, entry.key, allRoutes),
            child: _buildScreenContent(context, layout, flat, entry.key),
          ),
        ),
    ];
  }

  void _onWidgetDropped(PaletteItem item, String screenKey) {
    // For now, show confirmation. Full AST insertion is wired in Phase 2.3+.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added ${item.label} to $screenKey'),
      backgroundColor: Colors.teal,
      duration: const Duration(seconds: 2),
    ));
    // If the screen has a selected component, insert after it
    final layout = context.read<CanvasLayoutController>();
    if (layout.selectedComponentId != null) {
      _editor.insertComponent(layout.selectedComponentId);
    }
  }

  Widget _buildScreenContent(BuildContext context,
      CanvasLayoutController layout, Map<String, AppRouteDef> flat,
      String key) {
    final route = flat[key];
    final content = DropTargetOverlay(
      onDrop: (item) => _onWidgetDropped(item, key),
      child: CurrentRouteProvider(
        routePath: route?.name ?? route?.path ?? '',
        child: route?.builder(context) ??
            const Center(child: Text('Not Found')),
      ),
    );
    if (layout.previewMode == PreviewMode.allDevices) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: AppDevices.values.asMap().entries.map((devEntry) {
          return Padding(
            padding: EdgeInsets.only(
              right: devEntry.key < AppDevices.values.length - 1
                  ? CanvasLayoutController.deviceSpacing
                  : 0,
            ),
            child: CanvasDevicePreview(
              device: devEntry.value,
              route: route,
              content: content,
              onLoadInspector: _loadInspector,
            ),
          );
        }).toList(),
      );
    }
    return CanvasDevicePreview(
      device: layout.singleDevice!,
      route: route,
      content: content,
      onLoadInspector: _loadInspector,
    );
  }

  Widget _buildResizeHandle(CanvasLayoutController layout) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => layout.startDragResize(),
        onHorizontalDragUpdate: (d) => layout.updateInspectorWidth(
            d.delta.dx, MediaQuery.of(context).size.width / 2),
        onHorizontalDragEnd: (_) => layout.endDragResize(),
        child: Container(width: 4, color: Colors.transparent),
      ),
    );
  }

  Widget _buildPropertiesPanel(
      BuildContext context, CanvasLayoutController layout) {
    return AnimatedContainer(
      duration: layout.isDragging
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: layout.isPanelOpen ? layout.inspectorWidth : 0.0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        boxShadow: [
          if (layout.isPanelOpen)
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(-2, 0)),
        ],
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: layout.inspectorWidth,
          maxWidth: layout.inspectorWidth,
          child: Theme(
            data: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blueGrey, brightness: Brightness.light),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(fontSize: 14),
                bodyMedium: TextStyle(fontSize: 13),
                bodySmall: TextStyle(fontSize: 11),
                labelLarge:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            child: Builder(
              builder: (editorCtx) => CanvasLiveEditorPanel(
                inspectorFilePath: _editor.inspectedFilePath,
                inspectorFields: _editor.inspectedFields,
                inspectorIsLoading: _editor.isInspectorLoading,
                selectedComponentId: layout.selectedComponentId,
                onUpdateStyleField: _editor.updateStyleField,
                onPromoteToken: _editor.promoteToken,
                showBackgroundDecor: layout.showBackgroundDecor,
                onToggleBackgroundDecor: layout.setShowBackgroundDecor,
                onExportAndSaveCode: exportAndSaveCanvasTheme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
