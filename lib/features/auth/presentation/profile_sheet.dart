import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.person_outline),
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (c) => const _Sheet(),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Anonymous user (wire up Firebase Auth later)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
