import 'package:flutter/material.dart';

/// キャンバス上に描画されるリンク情報のデータ構造
class CanvasLinkData {
  final String sourceRoute;
  final String targetRoute;
  final Offset sourceCenter; // キャンバス座標系でのボタン中心位置

  CanvasLinkData({
    required this.sourceRoute,
    required this.targetRoute,
    required this.sourceCenter,
  });
}

/// キャンバス全体でリンク情報を収集・管理するコントローラー
class CanvasLinkRegistry extends ChangeNotifier {
  final Map<String, CanvasLinkData> _links = {}; // WidgetのhashCodeなどをキーにして重複を防ぐ
  
  Map<String, CanvasLinkData> get links => Map.unmodifiable(_links);

  void registerLink(String key, CanvasLinkData data) {
    // 既に全く同じデータが登録されている場合は再描画を防ぐ
    final existing = _links[key];
    if (existing != null &&
        existing.sourceRoute == data.sourceRoute &&
        existing.targetRoute == data.targetRoute &&
        (existing.sourceCenter - data.sourceCenter).distance < 0.1) {
      return; 
    }
    
    _links[key] = data;
    notifyListeners();
  }

  void unregisterLink(String key) {
    if (_links.remove(key) != null) {
      notifyListeners();
    }
  }

  static CanvasLinkRegistry? maybeOf(BuildContext context) {
    // listen: false にするため、依存関係を登録しない getElementFor... を使用
    try {
      final element = context.getElementForInheritedWidgetOfExactType<InheritedRegistry>();
      return (element?.widget as InheritedRegistry?)?.registry;
    } catch (_) {
      return null;
    }
  }
}

/// レジストリを配下に提供するためのInheritedWidget
class InheritedRegistry extends InheritedWidget {
  final CanvasLinkRegistry registry;
  final GlobalKey canvasKey;

  const InheritedRegistry({
    super.key,
    required this.registry,
    required this.canvasKey,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedRegistry oldWidget) {
    return registry != oldWidget.registry || canvasKey != oldWidget.canvasKey;
  }
}

/// プレビュー枠が「今どのルートを描画しているか」を配下に教えるためのProvider
class CurrentRouteProvider extends InheritedWidget {
  final String routePath;

  const CurrentRouteProvider({
    super.key,
    required this.routePath,
    required super.child,
  });

  static String? maybeOf(BuildContext context) {
    try {
      final element = context.getElementForInheritedWidgetOfExactType<CurrentRouteProvider>();
      return (element?.widget as CurrentRouteProvider?)?.routePath;
    } catch (_) {
      return null;
    }
  }

  @override
  bool updateShouldNotify(CurrentRouteProvider oldWidget) => routePath != oldWidget.routePath;
}

/// アプリ開発者が各画面のボタンなどをラップするためのWidget
class CanvasLink extends StatefulWidget {
  final String target;
  final Widget child;

  const CanvasLink({
    super.key,
    required this.target,
    required this.child,
  });

  @override
  State<CanvasLink> createState() => _CanvasLinkState();
}

class _CanvasLinkState extends State<CanvasLink> {
  String get _linkKey => identityHashCode(this).toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPosition());
  }

  @override
  void didUpdateWidget(CanvasLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPosition());
  }

  @override
  void deactivate() {
    final registry = CanvasLinkRegistry.maybeOf(context);
    registry?.unregisterLink(_linkKey);
    super.deactivate();
  }

  void _registerPosition() {
    if (!mounted) return;
    
    final registryElement = context.getElementForInheritedWidgetOfExactType<InheritedRegistry>();
    final inheritedRegistry = registryElement?.widget as InheritedRegistry?;
    if (inheritedRegistry == null) return; // キャンバス外（本番環境など）では何もしない
    
    final sourceRoute = CurrentRouteProvider.maybeOf(context);
    if (sourceRoute == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final canvasContext = inheritedRegistry.canvasKey.currentContext;
    if (canvasContext == null) return;
    final canvasBox = canvasContext.findRenderObject() as RenderBox?;
    if (canvasBox == null) return;

    // キャンバス基準の座標へ変換
    final localCenter = Offset(box.size.width / 2, box.size.height / 2);
    final globalPosition = box.localToGlobal(localCenter, ancestor: canvasBox);

    inheritedRegistry.registry.registerLink(
      _linkKey,
      CanvasLinkData(
        sourceRoute: sourceRoute,
        targetRoute: widget.target,
        sourceCenter: globalPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
