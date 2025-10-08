import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Mini Finance',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A lightweight tracker with AI insights. Start by signing in or try the demo dashboard.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.go('/signin'),
              icon: const Icon(Icons.login),
              label: const Text('Sign in / Create account'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Continue to demo dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
