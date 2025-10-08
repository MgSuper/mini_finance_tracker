import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:uuid/uuid.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final catsAsync = ref.watch(categoriesProvider);

    final catsMap = ref.watch(categoriesMapProvider);

    Future<void> _addDialog() async {
      final form = GlobalKey<FormState>();
      String field = 'merchant';
      final containsCtrl = TextEditingController();
      String? categoryId;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Rule'),
          content: catsAsync.when(
            loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (cats) {
              if (categoryId == null && cats.isNotEmpty) {
                categoryId = cats.first.id;
              }

              return Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: field,
                      decoration: const InputDecoration(labelText: 'Field'),
                      items: const [
                        DropdownMenuItem(
                            value: 'merchant', child: Text('Merchant')),
                        DropdownMenuItem(
                            value: 'description', child: Text('Description')),
                      ],
                      onChanged: (v) => field = v ?? 'merchant',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: containsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contains (case-insensitive)',
                        hintText: 'e.g., starbucks',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a keyword'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem<String>(
                              value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => categoryId = v,
                      validator: (v) => v == null ? 'Pick a category' : null,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!(form.currentState?.validate() ?? false)) return;
                try {
                  ref.read(authUidProvider); // require UID

                  final repo = ref.read(ruleRepositoryProvider);
                  final id = const Uuid().v4();
                  final rule = RuleModel(
                    id: id,
                    field: field,
                    contains: containsCtrl.text.trim().toLowerCase(),
                    categoryId: categoryId!,
                  );
                  await repo?.add(rule);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Rule added')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('❌ $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No rules yet'));

          Future<bool?> _confirmDelete(BuildContext context) {
            return showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete rule?'),
                content: const Text(
                    'This will stop auto-tagging for this condition.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete')),
                ],
              ),
            );
          }

          Future<void> _editDialog(RuleModel r) async {
            final form = GlobalKey<FormState>();
            String field = r.field;
            final containsCtrl = TextEditingController(text: r.contains);
            String? categoryId = r.categoryId;

            final catsAsync = ref.read(categoriesProvider);
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Edit Rule'),
                content: catsAsync.when(
                  loading: () => const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error: $e'),
                  data: (cats) => Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: field,
                          decoration: const InputDecoration(labelText: 'Field'),
                          items: const [
                            DropdownMenuItem(
                                value: 'merchant', child: Text('Merchant')),
                            DropdownMenuItem(
                                value: 'description',
                                child: Text('Description')),
                          ],
                          onChanged: (v) => field = v ?? 'merchant',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: containsCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Contains'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a keyword'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(
                                  value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) => categoryId = v,
                          validator: (v) =>
                              v == null ? 'Pick a category' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () async {
                      if (!(form.currentState?.validate() ?? false)) return;
                      try {
                        ref.read(authUidProvider);
                        final repo = ref.read(ruleRepositoryProvider);
                        final updated = RuleModel(
                          id: r.id,
                          field: field,
                          contains: containsCtrl.text.trim().toLowerCase(),
                          categoryId: categoryId!,
                        );
                        await repo?.update(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Rule updated')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = items[i];
              final cat = catsMap[r.categoryId]; // 👈 join by id
              final catName = cat?.name ?? '(category removed)';
              final catColor = cat != null
                  ? Color(
                      int.parse(cat.color.replaceFirst('#', 'FF'), radix: 16))
                  : null;
              return Dismissible(
                key: ValueKey('rule_${r.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) async {
                  try {
                    ref.read(authUidProvider);
                    await ref.read(ruleRepositoryProvider)?.delete(r.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🗑️ Rule deleted')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e')),
                    );
                  }
                },
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: Icon(
                      r.field == 'merchant' ? Icons.store : Icons.description),
                  title: Text('${r.field} contains “${r.contains}”'),
                  subtitle: Row(
                    children: [
                      const Text('→ category: '),
                      if (catColor != null) ...[
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: catColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                      ],
                      Text(catName),
                    ],
                  ),
                  onTap: () => _editDialog(r),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editDialog(r),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
