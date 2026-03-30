import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/canvas_link.dart';
import '../../core/design_system/linter_wrapper.dart';
import '../../widgets/my_custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
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
              const Text('⚠️ Visual Linter Test:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}
