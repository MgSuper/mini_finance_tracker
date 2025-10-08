import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:mini_finan/features/transactions/logic/rule_engine.dart';

final addTxControllerProvider =
    AutoDisposeAsyncNotifierProvider<AddTxController, void>(
  () => AddTxController(),
);

class AddTxController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves a new transaction (or updates an existing one if [editId] is set).
  /// Amount text is parsed as a **positive** number and then re-signed based on
  /// the **final** category (after rule application).
  Future<TxModel> save({
    required String amountText,
    required String currency,
    required String merchant,
    required String description,
    required String categoryId, // initial pick (may be overridden by rule)
    required DateTime date,
    String? editId,
    DateTime? createdAt, // keep original when editing
  }) async {
    state = const AsyncLoading();
    try {
      // 1) Require a signed-in user early (fail-fast)
      ref.read(authUidProvider);

      // 2) Parse as absolute (we control the sign)
      final parsedAbs = double.tryParse(
            amountText.replaceAll(',', '').replaceAll(' ', ''),
          ) ??
          double.nan;
      if (parsedAbs.isNaN || parsedAbs <= 0) {
        throw 'Invalid amount (use a positive number like 12.34)';
      }

      // 3) Load rules & categories (await once if not ready yet)
      var rules = ref.read(rulesProvider).maybeWhen(
            data: (r) => r,
            orElse: () => const <RuleModel>[],
          );
      var cats = ref.read(categoriesProvider).maybeWhen(
            data: (c) => c,
            orElse: () => const <CategoryModel>[],
          );
      if (rules.isEmpty) rules = await ref.read(rulesProvider.future);
      if (cats.isEmpty) cats = await ref.read(categoriesProvider.future);

      final now = DateTime.now();
      final id = editId ?? const Uuid().v4();

      // 4) Build a base tx and run rule engine to finalize category
      final base = TxModel(
        id: id,
        accountId: 'default',
        date: DateTime(date.year, date.month, date.day),
        amount: 0, // placeholder – will be set after category is final
        currency: currency,
        merchant: merchant.trim(),
        descriptionRaw: description.trim(),
        categoryId: categoryId,
        createdAt: createdAt ?? now,
        updatedAt: now,
      );

      final withRule = applyRules(tx: base, rules: rules, categories: cats);
      final finalCatId = withRule.categoryId;

      // 5) Decide the sign by the final category's type
      final finalCat = cats.firstWhere(
        (c) => c.id == finalCatId,
        orElse: () => throw 'Category not found',
      );

      final signedAmount = finalCat.type == CategoryType.income
          ? parsedAbs.abs()
          : -parsedAbs.abs();

      final toSave = withRule.copyWith(
        amount: signedAmount,
        updatedAt: now,
      );

      // 6) Persist
      final repo = ref.read(transactionRepositoryProvider);
      await repo.upsert(toSave);

      state = const AsyncData(null);
      return toSave;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
