import 'package:go_router/go_router.dart';
void main() {
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => throw '')]);
  print(router.configuration);
}
