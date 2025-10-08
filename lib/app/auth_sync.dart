import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/dashboard/providers.dart';

class AuthSync extends ConsumerWidget {
  const AuthSync({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attach listener here – this is safe
    ref.listen<User?>(
      authStateChangesProvider.select((a) => a.value),
      (prev, next) {
        // Invalidate Firestore-backed providers when auth changes
        ref.invalidate(transactionsStreamProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(rulesProvider);
      },
    );

    return child;
  }
}
