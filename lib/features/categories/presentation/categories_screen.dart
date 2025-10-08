import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/category_repository.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);

    Future<void> _addDialog() async {
      final form = GlobalKey<FormState>();
      final nameCtrl = TextEditingController();
      final codeCtrl = TextEditingController();
      final colorCtrl = TextEditingController(text: '#FF9800');
      CategoryType _type = CategoryType.expense; // default

      String slugify(String s) => s
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      void syncCodeFromName() {
        if (codeCtrl.text.trim().isEmpty) {
          codeCtrl.text = slugify(nameCtrl.text);
        }
      }

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Category'),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (_) => syncCodeFromName(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Code (e.g. food_drink)'),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Enter a code';
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(t)) {
                        return 'Only lowercase letters, numbers, underscore';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: colorCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Color (hex, e.g. #FF9800)'),
                    validator: (v) => (v == null ||
                            !RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(v.trim()))
                        ? 'Invalid hex'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CategoryType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                          value: CategoryType.income, child: Text('Income')),
                      DropdownMenuItem(
                          value: CategoryType.expense, child: Text('Expense')),
                    ],
                    onChanged: (v) {
                      if (v != null) _type = v;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(form.currentState?.validate() ?? false)) return;
                try {
                  ref.read(authUidProvider); // require UID

                  final repo = ref.read(categoriesRepositoryProvider);
                  final id = const Uuid().v4();
                  var hex = colorCtrl.text.trim();
                  if (!hex.startsWith('#')) hex = '#$hex';

                  final cat = CategoryModel(
                    id: id,
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim(),
                    color: hex,
                    type: _type,
                  );
                  await repo.addCategory(
                    name: cat.name,
                    code: cat.code,
                    color: cat.color,
                    type: cat.type,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Category added')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }

          Future<bool?> _confirmDelete(BuildContext context, String name) {
            return showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete category?'),
                content: Text(
                    'This will remove “$name”. Transactions keep their old categoryId.'),
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

          Future<void> _editDialog(CategoryModel c) async {
            final form = GlobalKey<FormState>();
            final nameCtrl = TextEditingController(text: c.name);
            final codeCtrl = TextEditingController(text: c.code);
            final colorCtrl = TextEditingController(text: c.color);
            var _type = c.type;

            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Edit Category'),
                content: Form(
                  key: form,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a name'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(labelText: 'Code'),
                          validator: (v) => (v == null ||
                                  !RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim()))
                              ? 'Lowercase letters, numbers, _'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Color (hex, e.g. #FF9800)'),
                          validator: (v) => (v == null ||
                                  !RegExp(r'^#?[0-9A-Fa-f]{6}$')
                                      .hasMatch(v.trim()))
                              ? 'Invalid hex'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<CategoryType>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(
                                value: CategoryType.income,
                                child: Text('Income')),
                            DropdownMenuItem(
                                value: CategoryType.expense,
                                child: Text('Expense')),
                          ],
                          onChanged: (v) {
                            if (v != null) _type = v;
                          },
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
                        final repo = ref.read(categoriesRepositoryProvider);
                        var hex = colorCtrl.text.trim();
                        if (!hex.startsWith('#')) hex = '#$hex';
                        await repo.updateCategory(
                          c.id,
                          name: nameCtrl.text.trim(),
                          code: codeCtrl.text.trim(),
                          color: hex,
                          type: _type,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Category updated')),
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
              final c = items[i];
              final color = _parseHex(c.color);
              final typeLabel =
                  c.type == CategoryType.income ? 'Income' : 'Expense';
              return Dismissible(
                key: ValueKey('cat_${c.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, c.name),
                onDismissed: (_) async {
                  try {
                    ref.read(authUidProvider);
                    await ref
                        .read(categoriesRepositoryProvider)
                        .deleteCategory(c.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🗑️ Deleted “${c.name}”')),
                    );
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
                  leading: CircleAvatar(backgroundColor: color),
                  title: Text(c.name),
                  subtitle: Text('${c.code} • $typeLabel'),
                  onTap: () => _editDialog(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editDialog(c),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _parseHex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }
}
