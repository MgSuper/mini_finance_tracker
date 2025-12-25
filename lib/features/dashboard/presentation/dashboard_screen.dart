import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_finan/features/auth/presentation/widgets/accounts_bottom_sheet.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:mini_finan/features/auth/providers/auth_ui_providers.dart';
import 'package:mini_finan/features/dashboard/providers.dart';

// ✅ server driven ui
import 'package:mini_finan/features/server_ui/providers/server_ui_providers.dart';
import 'package:mini_finan/features/server_ui/presentation/dashboard_section_renderer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(authLabelProvider);
    final uid = ref.watch(authUidNullableProvider);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          elevation: 0,
          title: const Text('Dashboard'),
        ),
        body: const Center(child: Text('Sign in to see your dashboard.')),
      );
    }

    final uiAsync = ref.watch(uiConfigProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showAccountsBottomSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'import' => context.push('/import'),
              'categories' => context.push('/categories'),
              'rules' => context.push('/rules'),
              'more' => context.push('/more'),
              _ => null,
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'import', child: Text('Import CSV')),
              PopupMenuItem(
                  value: 'categories', child: Text('Manage Categories')),
              PopupMenuItem(value: 'rules', child: Text('Manage Rules')),
              PopupMenuItem(value: 'more', child: Text('More…')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Your existing refresh behavior
          ref.invalidate(nowProvider);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: uiAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Failed to load dashboard config: $e'),
              const SizedBox(height: 8),
              const Text(
                  'Check Firestore: ui_configs/dev (or prod) exists and shape is correct.'),
            ],
          ),
          data: (cfg) {
            final sections = cfg.dashboard.sections;
            if (sections.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('No dashboard sections configured.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) =>
                  DashboardSectionRenderer(section: sections[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
