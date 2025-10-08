import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.error,
    this.onRetry,
    this.onSignIn,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String subtitle = error.toString();
    List<Widget> actions = [];

    if (error is FirebaseException &&
        (error as FirebaseException).code == 'permission-denied') {
      title = 'Permission needed';
      subtitle = 'You don’t have access to this data. '
          'Please sign in again or retry.';
      if (onSignIn != null) {
        actions
            .add(TextButton(onPressed: onSignIn, child: const Text('Sign in')));
      }
    }

    if (onRetry != null) {
      actions.add(TextButton(onPressed: onRetry, child: const Text('Retry')));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: actions),
            ]
          ],
        ),
      ),
    );
  }
}
