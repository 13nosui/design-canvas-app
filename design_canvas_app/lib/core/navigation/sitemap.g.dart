// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/settings_page.dart';

class CanvasRoute {
  final String name;
  final String path;
  final WidgetBuilder builder;
  final List<String> childrenNames;
  const CanvasRoute({required this.name, required this.path, required this.builder, required this.childrenNames});
}

final Map<String, CanvasRoute> generatedRoutes = {
  'Login': CanvasRoute(
    name: 'Login',
    path: '/login',
    builder: (context) => const LoginPage(),
    childrenNames: const [],
  ),
  'Home': CanvasRoute(
    name: 'Home',
    path: '/',
    builder: (context) => const HomePage(),
    childrenNames: const ['Settings'],
  ),
  'Settings': CanvasRoute(
    name: 'Settings',
    path: 'settings',
    builder: (context) => const SettingsPage(),
    childrenNames: const [],
  ),
};
