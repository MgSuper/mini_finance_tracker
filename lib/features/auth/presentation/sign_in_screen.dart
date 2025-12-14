import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  Future<void> seedDefaults(WidgetRef ref) async {
    final uid = ref.read(authUidProvider);

    final firestore = FirebaseFirestore.instance;
    final catCol =
        firestore.collection('users').doc(uid).collection('categories');

    final snap = await catCol.limit(1).get();
    if (snap.docs.isEmpty) {
      await catCol.doc().set({
        'name': 'Food & Drink',
        'code': 'food_drink',
        'color': '#FF9800',
        'type': 'expense',
      });
      await catCol.doc().set({
        'name': 'Groceries',
        'code': 'groceries',
        'color': '#4CAF50',
        'type': 'expense',
      });
      await catCol.doc().set({
        'name': 'Transport',
        'code': 'transport',
        'color': '#2196F3',
        'type': 'expense',
      });
      await catCol.doc().set({
        'name': 'Income',
        'code': 'income',
        'color': '#009688',
        'type': 'income',
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authControllerProvider);
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Continue (Anonymous)'),
          onPressed: () async {
            try {
              // ✅ Wait for sign-in
              await auth.signInAnonymously();

              // Now seed after UID is guaranteed
              await seedDefaults(ref);

              // if (context.mounted) {
              //   context.go('/transactions');
              // }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ $e')),
              );
            }
          },
        ),
      ),
    );
  }
}
