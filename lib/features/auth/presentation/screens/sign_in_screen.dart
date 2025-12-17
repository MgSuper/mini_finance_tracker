import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> seedDefaults(WidgetRef ref) async {
    final uid = ref.read(authUidProvider);

    final firestore = FirebaseFirestore.instance;
    final catCol =
        firestore.collection('users').doc(uid).collection('categories');

    // Seed only if empty (safe for returning users)
    final snap = await catCol.limit(1).get();
    if (snap.docs.isNotEmpty) return;

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

  Future<void> _runWithLoading(Future<void> Function() fn) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await fn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mini Finance Tracker',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Continue anonymously or sign in to your account.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // -------- Email Sign In --------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Enter email';
                                if (!t.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) {
                                final t = v ?? '';
                                if (t.isEmpty) return 'Enter password';
                                if (t.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.lock_open),
                                label: Text(
                                    _isLoading ? 'Signing in...' : 'Sign In'),
                                onPressed: _isLoading
                                    ? null
                                    : () => _runWithLoading(() async {
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          await auth.signInWithEmailAndPassword(
                                            email: _emailCtrl.text.trim(),
                                            password: _passCtrl.text,
                                          );

                                          // Seed defaults only if empty
                                          await seedDefaults(ref);
                                        }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // -------- Anonymous Sign In --------
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: Text(_isLoading
                          ? 'Please wait...'
                          : 'Continue (Anonymous)'),
                      onPressed: _isLoading
                          ? null
                          : () => _runWithLoading(() async {
                                await auth.signInAnonymously();
                                await seedDefaults(ref);
                              }),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Tip: You can upgrade from Anonymous to Email later from the Accounts sheet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
