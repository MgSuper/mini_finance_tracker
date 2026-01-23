import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebMobileFrame extends StatelessWidget {
  const WebMobileFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14), // optional
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), // optional
              child: ScaffoldMessenger(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
