import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:mini_finan/features/transactions/logic/rule_engine.dart';

final importControllerProvider =
    AutoDisposeAsyncNotifierProvider<ImportController, void>(
        () => ImportController());

class ImportController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Your existing mapper from CSV -> TxModel
  TxModel rowToTx({
    required Map<String, int> col,
    required List<String> row,
    required String currencyFallback,
  }) {
    String pick(String key, [String def = '']) {
      final i = col[key];
      return (i == null || i < 0 || i >= row.length) ? def : row[i].trim();
    }

    double parseNum(String s) =>
        double.tryParse(s.replaceAll(',', '').replaceAll(' ', '')) ?? 0.0;

    final rawDate = pick('date');
    final desc = pick('description');
    final merch = pick('merchant', desc);
    final currency = pick('currency', currencyFallback);

    final hasAmount = pick('amount').isNotEmpty;
    final amount = hasAmount
        ? parseNum(pick('amount'))
        : (parseNum(pick('credit')) - parseNum(pick('debit')));

    DateTime parseDate(String s) {
      final t = s.trim();
      // quick formats; extend as you need
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) {
        return DateTime.parse(t);
      }
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(t)) {
        final p = t.split('/');
        return DateTime(int.parse(p[2]), int.parse(p[0]), int.parse(p[1]));
      }
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(t)) {
        final p = t.split('-');
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
      return DateTime.tryParse(t) ?? DateTime.now();
    }

    final now = DateTime.now();
    final isIncome = amount > 0;
    final cat = pick('category', isIncome ? 'income' : 'uncategorized');

    return TxModel(
      id: UniqueKey().toString(), // or uuid if you prefer
      accountId: 'import',
      date: parseDate(rawDate),
      amount: amount,
      currency: currency.isEmpty ? 'USD' : currency,
      merchant: merch,
      descriptionRaw: desc,
      categoryId: cat,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Commit mapped rows → apply rules → write
  Future<int> commit({
    required List<List<String>> rows,
    required Map<String, int> mapping,
    required String currencyFallback,
  }) async {
    state = const AsyncLoading();
    try {
      // ✅ Require UID (fast fail if signed out)
      ref.read(authUidProvider);

      final repo = ref.read(transactionRepositoryProvider);

      // 🧠 Load rules & categories once for the whole batch
      // final rules = await ref.read(rulesProvider.future);
      // final cats = await ref.read(categoriesProvider.future);

      final rulesState = ref.read(rulesProvider);
      final catsState = ref.read(categoriesProvider);

      var rules = rulesState.maybeWhen(
          data: (r) => r, orElse: () => const <RuleModel>[]);
      var cats = catsState.maybeWhen(
          data: (c) => c, orElse: () => const <CategoryModel>[]);

      if (rules.isEmpty) rules = await ref.read(rulesProvider.future);
      if (cats.isEmpty) cats = await ref.read(categoriesProvider.future);

      var count = 0;
      for (final r in rows) {
        final base =
            rowToTx(col: mapping, row: r, currencyFallback: currencyFallback);
        final tagged = applyRules(tx: base, rules: rules, categories: cats)
            .copyWith(updatedAt: DateTime.now());
        await repo.upsert(tagged);
        count++;
      }

      state = const AsyncData(null);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
