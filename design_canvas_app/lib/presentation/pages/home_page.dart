import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/canvas_link.dart';
import '../../core/design_system/theme_controller.dart';
import '../../core/design_system/linter_wrapper.dart';
import '../../widgets/my_custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockState = ThemeControllerProvider.of(context).currentMockState;

    Widget content;
    switch (mockState) {
      case MockUIState.loading:
        content = const CircularProgressIndicator();
        break;
      case MockUIState.empty:
        content = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('データがありません', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        );
        break;
      case MockUIState.error:
        content = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text('エラーが発生しました', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        );
        break;
      case MockUIState.normal:
        content = SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Home',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CanvasLink(
                target: '/profile',
                child: MyCustomButton(
                  text: 'Go to Profile',
                  onPressed: () {
                    context.go('/profile');
                  },
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('⚠️ 今度こそ！おーまいハッハッハ。Visual Linter Test:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinterWrapper(
                isCompliant: false,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    // マジックナンバーを直書きした違反コンポーネントの例
                    padding: const EdgeInsets.all(13.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF123456),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: const Text('Bad Button (Magic Numbers)', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 1,
      ),
      body: Center(
        child: content,
      ),
    );
  }
}
