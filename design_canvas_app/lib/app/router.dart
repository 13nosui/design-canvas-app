import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/settings_page.dart';

// CanvasとGoRouterで共有するための単一ルート定義
class AppRouteDef {
  final String path;
  final String? name; // nullの場合はpathをnameとして扱う
  final WidgetBuilder builder;
  final List<AppRouteDef> children;

  const AppRouteDef(this.path, this.name, this.builder, [this.children = const []]);

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
  AppRouteDef('/login', 'Login', (c) => const LoginPage()),
  AppRouteDef('/', 'Home', (c) => const HomePage(), [
    AppRouteDef('settings', 'Settings', (c) => const SettingsPage()),
  ]),
  AppRouteDef('/profile', 'profile', (c) => const Scaffold(body: Center(child: Text('Profile Page')))),
  AppRouteDef('/timeline', 'timeline', (c) => const Scaffold(body: Center(child: Text('Timeline Page')))),
];

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: canvasRoutes.map((r) => r.toGoRoute()).toList(),
);
