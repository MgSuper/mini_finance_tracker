import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/add_tx_controller.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/logic/rule_engine.dart';
import 'package:mini_finan/features/transactions/transaction_detail_providers.dart'; // txByIdProvider

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _currency = 'USD';
  String? _categoryId;

  bool _forceCategoryValidation = false;

  // 👇 ensures we only prefill once when editing
  bool _prefilled = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 2);
    final last = DateTime(now.year + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit({TxModel? editingTx}) async {
    // Validate amount/merchant/etc. (category may be enforced later)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ctrl = ref.read(addTxControllerProvider.notifier);

    try {
      // 1) Load rules & categories snapshot
      var rules = ref
          .read(rulesProvider)
          .maybeWhen(data: (r) => r, orElse: () => const <RuleModel>[]);
      var cats = ref
          .read(categoriesProvider)
          .maybeWhen(data: (c) => c, orElse: () => const <CategoryModel>[]);
      if (rules.isEmpty) rules = await ref.read(rulesProvider.future);
      if (cats.isEmpty) cats = await ref.read(categoriesProvider.future);

      // 2) Build temporary Tx to run rule matching (category may be null)
      final tmpNow = DateTime.now();
      final tmp = TxModel(
        id: editingTx?.id ?? 'tmp',
        accountId: editingTx?.accountId ?? '',
        date: DateTime(_date.year, _date.month, _date.day),
        amount: editingTx?.amount ?? 0, // not used for rule match
        currency: _currency,
        merchant: _merchantCtrl.text.trim(),
        descriptionRaw: _descCtrl.text.trim(),
        categoryId: _categoryId ?? 'none', // placeholder to detect change
        createdAt: editingTx?.createdAt ?? tmpNow,
        updatedAt: tmpNow,
      );

      final resolved = applyRules(tx: tmp, rules: rules, categories: cats);
      final didMatch = resolved.categoryId != tmp.categoryId;
      final effectiveCategoryId = didMatch ? resolved.categoryId : _categoryId;

      // 3) If NO rule matched AND user didn’t pick a category → enforce validator
      if (!didMatch &&
          (effectiveCategoryId == null || effectiveCategoryId.isEmpty)) {
        setState(() => _forceCategoryValidation = true);
        _formKey.currentState!.validate(); // will show "Pick a category"
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a category')),
        );
        return;
      }

      // 4) Save via controller (edit-aware)
      await ctrl.save(
        amountText: _amountCtrl.text,
        currency: _currency,
        merchant: _merchantCtrl.text,
        description: _descCtrl.text,
        categoryId: effectiveCategoryId!, // now guaranteed
        date: DateTime(_date.year, _date.month, _date.day),

        // 👇 pass edit info if present
        editId: editingTx?.id,
        createdAt: editingTx?.createdAt,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            didMatch
                ? (editingTx == null
                    ? '✅ Transaction added (auto-tagged by rule)'
                    : '✅ Transaction updated (auto-tagged by rule)')
                : (editingTx == null
                    ? '✅ Transaction added!'
                    : '✅ Transaction updated!'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── EDIT MODE? read id from query ───────────────────────────────────────
    final editId = GoRouterState.of(context).uri.queryParameters['id'];
    final txAv = (editId == null) ? null : ref.watch(txByIdProvider(editId));
    final editingTx = txAv?.maybeWhen(data: (t) => t, orElse: () => null);

    // Prefill *once* when edit data becomes available
    if (!_prefilled && editingTx != null) {
      _prefilled = true;
      _amountCtrl.text = editingTx.amount.abs().toStringAsFixed(2);
      _currency = editingTx.currency;
      _merchantCtrl.text = editingTx.merchant;
      _descCtrl.text = editingTx.descriptionRaw;
      _categoryId = editingTx.categoryId;
      _date = editingTx.date;
    }

    final catsAsync = ref.watch(categoriesProvider);
    final state = ref.watch(addTxControllerProvider);
    final isEditing = editingTx != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: false),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  hintText: 'e.g., 12.90',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  final n = double.tryParse(v.replaceAll(',', '').trim());
                  if (n == null) return 'Invalid number';
                  if (n <= 0) return 'Enter a positive value';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: const ['USD', 'EUR', 'VND', 'SGD', 'JPY']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? 'USD'),
              ),
              const SizedBox(height: 12),

              // Category picker: validator turns on only if rule didn't match and user didn't pick
              catsAsync.when(
                data: (cats) {
                  return DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in cats)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) {
                      if (_forceCategoryValidation &&
                          (v == null || v.isEmpty)) {
                        return 'Pick a category';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Error loading categories: $e'),
                ),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  hintText: 'e.g., Coffee Bar',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_date.toLocal()}'.split(' ').first),
                trailing: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () => _submit(editingTx: editingTx),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save changes' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
