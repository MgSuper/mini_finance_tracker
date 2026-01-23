import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_finan/app/providers/theme_mode_provider.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggle = ref.watch(themeModeProvider);
    return Scaffold(
      appBar:
          AppBar(centerTitle: false, elevation: 0, title: const Text('More')),
      body: ListView(
        children: [
          const _SectionLabel('Data & Tools'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import CSV'),
            subtitle: const Text('Upload bank statements and auto-tag'),
            onTap: () => context.push('/import'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, delete categories'),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('Manage Rules'),
            subtitle: const Text('Auto-tagging conditions'),
            onTap: () => context.push('/rules'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const _SectionLabel('Explore'),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Transactions'),
            onTap: () => context.push('/transactions'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const _SectionLabel('Settings'),
          ListTile(
            leading: toggle == ThemeMode.dark
                ? const Icon(Icons.dark_mode_outlined)
                : const Icon(Icons.light_mode_outlined),
            title: const Text('Theme Mode'),
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
