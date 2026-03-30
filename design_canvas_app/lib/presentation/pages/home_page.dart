import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/canvas_link.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
