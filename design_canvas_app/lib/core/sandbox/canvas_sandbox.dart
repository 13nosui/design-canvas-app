import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mockable_states.dart';

/// ----------------------------------------------------
/// CanvasSandbox
/// ----------------------------------------------------
/// このウィジェットで囲まれたコンポーネント（UI）は、自動的に
/// モック化（MockAuthState等）された依存を Provider 経由で受け取るため、
/// バックエンドが起動していなくても正常に描画・テストが可能になります。
class CanvasSandbox extends StatelessWidget {
  final Widget child;

  const CanvasSandbox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Scaffoldが要求するウィジェットもあるため、ここで最小限のフレームワーク環境を用意する
    return MultiProvider(
      providers: [
        // インターフェースである `AuthState` に対して、`MockAuthState` の実装を供給する
        ChangeNotifierProvider<AuthState>(create: (_) => MockAuthState()),
        // 必要であれば、FeedStateのモックなどもここに追加する
      ],
      child: Scaffold(
        body: child,
      ),
    );
  }
}
