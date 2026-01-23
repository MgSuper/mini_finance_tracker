import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:mini_finan/widgets/loader.dart';

class SignInScreen extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Listen for errors to show SnackBars
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      state.whenOrNull(error: (err, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $err')),
        );
      });
    });
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Decoration (Optional Stack use-case)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Icon(Icons.account_balance_wallet,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Mini Finance Tracker',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continue anonymously or sign in to your account.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Email Sign In Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return 'Enter email';
                              if (!t.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = v ?? '';
                              if (t.isEmpty) return 'Enter password';
                              if (t.length < 6) return 'Min 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                                icon: isLoading
                                    ? const Loader() // <--- Use here when loading
                                    : const Icon(Icons.lock_open),
                                label: Text(
                                    isLoading ? 'Signing in...' : 'Sign In'),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          ref
                                              .read(authControllerProvider
                                                  .notifier)
                                              .signInWithEmailAndPassword(
                                                email: _emailCtrl.text,
                                                password: _passCtrl.text,
                                              );
                                        }
                                      }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR')),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Anonymous Sign In
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: isLoading
                            ? const Loader() // <--- Use here when loading
                            : const Icon(Icons.person_outline),
                        label: Text(isLoading
                            ? 'Please wait...'
                            : 'Continue Anonymously'),
                        onPressed: isLoading
                            ? null
                            : () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signInAnonymously();
                              },
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Tip: You can upgrade from Anonymous to Email later from the Accounts sheet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
