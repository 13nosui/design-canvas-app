import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Login',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
