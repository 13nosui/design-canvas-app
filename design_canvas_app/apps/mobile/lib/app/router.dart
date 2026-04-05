import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/settings_page.dart';
import '../ui/page/common/sidebar.dart';
import '../core/sandbox/canvas_sandbox.dart';
import 'scanned_routes.dart';

// CanvasとGoRouterで共有するための単一ルート定義
class AppRouteDef {
  final String path;
  final String? name; // nullの場合はpathをnameとして扱う
  final WidgetBuilder builder;
  final List<AppRouteDef> children;
  final List<String> linksTo; // ボタンではなく画面自体から矢印を引く場合の対象パス
  final String? filePath; // IDEで開くためのソースコードのパス

  const AppRouteDef(
    this.path,
    this.name,
    this.builder, [
    this.children = const [],
    this.linksTo = const [],
    this.filePath,
  ]);

  // GoRouter用の変換メソッド
  GoRoute toGoRoute() {
    return GoRoute(
      path: path,
      name: name ?? path,
      builder: (context, state) => builder(context),
      routes: children.map((c) => c.toGoRoute()).toList(),
    );
  }
}

// デザインキャンバスとアプリ本体の「Single Source of Truth」となるリスト
final List<AppRouteDef> canvasRoutes = [
  // 例: Login画面からは、Home（'/'）へ遷移する
  AppRouteDef('/login', 'Login', (c) => const LoginPage(), [], ['/'],
      'lib/presentation/pages/login_page.dart'),

  // 例: Home画面からは、profileとtimelineへ遷移する
  AppRouteDef(
      '/',
      'Home',
      (c) => const HomePage(),
      [
        AppRouteDef('settings', 'Settings', (c) => const SettingsPage(), [], [],
            'lib/presentation/pages/settings_page.dart'),
      ],
      ['/profile', '/timeline'],
      'lib/presentation/pages/home_page.dart'), // ← ここにリンク先を配列で追加

  AppRouteDef(
      '/profile',
      'profile',
      (c) => const Scaffold(body: Center(child: Text('Profile Page'))),
      [],
      [],
      'lib/presentation/pages/profile_page.dart'),
  AppRouteDef(
      '/timeline',
      'timeline',
      (c) => const Scaffold(body: Center(child: Text('Timeline Page'))),
      [],
      [],
      'lib/presentation/pages/timeline_page.dart'),

  // サンドボックスを使ったTwitter CloneのSidebar (手動追加版)
  AppRouteDef(
      '/sandbox/sidebar',
      'Twitter Clone Sidebar\n(Canvas Sandbox)',
      (c) => const CanvasSandbox(child: SidebarMenu()),
      [],
      [],
      'lib/ui/page/common/sidebar.dart'),

  // ==========================================
  // 自動走査（スキャン）された未確認ページのルート群
  // bin/scan_pages.dart によって生成されます
  // ==========================================
  ...unconfirmedRoutes,
];

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: canvasRoutes.map((r) => r.toGoRoute()).toList(),
);
