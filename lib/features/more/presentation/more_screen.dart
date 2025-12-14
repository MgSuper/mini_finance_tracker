import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Divider(height: 32),
          const _SectionLabel('Explore'),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Transactions'),
            onTap: () => context.push('/transactions'),
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
