import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';

class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({
    super.key,
    this.initial,
    required this.onSubmit, // (name, color, type)
  });

  final CategoryModel? initial;
  final void Function(String name, String color, CategoryType type) onSubmit;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _color =
      TextEditingController(text: widget.initial?.color ?? '#FF9800');
  CategoryType _type = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _type = widget.initial!.type;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _color,
              decoration:
                  const InputDecoration(labelText: 'Color (hex, e.g. #FF9800)'),
              validator: (v) =>
                  (v == null || !RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(v))
                      ? 'Invalid hex'
                      : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<CategoryType>(
                    value: CategoryType.expense,
                    groupValue: _type,
                    onChanged: (t) => setState(() => _type = t!),
                    title: const Text('Expense'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<CategoryType>(
                    value: CategoryType.income,
                    groupValue: _type,
                    onChanged: (t) => setState(() => _type = t!),
                    title: const Text('Income'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            var hex = _color.text.trim();
            if (!hex.startsWith('#')) hex = '#$hex';
            widget.onSubmit(_name.text.trim(), hex, _type);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
