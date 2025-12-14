import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:mini_finan/features/transactions/logic/rule_engine.dart';
import 'package:uuid/uuid.dart';

final importControllerProvider =
    AutoDisposeAsyncNotifierProvider<ImportController, void>(
        () => ImportController());

class ImportController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  // ---------- helpers ----------

  String _pick(Map<String, int> col, List<String> row, String key,
      [String def = '']) {
    final i = col[key];
    return (i == null || i < 0 || i >= row.length) ? def : row[i].trim();
  }

  double _parseNum(String s) =>
      double.tryParse(s.replaceAll(',', '').replaceAll(' ', '')) ?? 0.0;

  DateTime _parseDate(String s) {
    final t = s.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) return DateTime.parse(t);

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

  String? _resolveCategoryIdFromCsv(String raw, List<CategoryModel> cats) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    // normalize
    final lower = t.toLowerCase();

    // 1) exact id match
    for (final c in cats) {
      if (c.id == t) return c.id;
    }

    // 2) code match
    for (final c in cats) {
      if (c.code.toLowerCase() == lower) return c.id;
    }

    // 3) name match
    for (final c in cats) {
      if (c.name.toLowerCase() == lower) return c.id;
    }

    return null;
  }

  String _defaultCategoryId({
    required bool hintIsIncome,
    required List<CategoryModel> cats,
  }) {
    if (hintIsIncome) {
      final income = cats.where((c) => c.type == CategoryType.income).toList();
      if (income.isNotEmpty) return income.first.id;
    }

    final expense = cats.where((c) => c.type == CategoryType.expense).toList();
    if (expense.isNotEmpty) return expense.first.id;

    return cats.isNotEmpty ? cats.first.id : 'uncategorized';
  }

  double _signedAmountFromCategory({
    required double amountAbs,
    required String categoryId,
    required List<CategoryModel> cats,
  }) {
    final cat = cats.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw 'Category not found for id=$categoryId',
    );

    return cat.type == CategoryType.income ? amountAbs : -amountAbs;
  }

  // ---------- main mapping ----------

  /// Returns:
  /// - base TxModel (amount raw for now)
  /// - hasExplicitCategory = CSV category successfully mapped to a real category doc id
  ({TxModel tx, bool hasExplicitCategory}) _rowToBaseTx({
    required Map<String, int> col,
    required List<String> row,
    required String currencyFallback,
    required List<CategoryModel> cats,
  }) {
    final rawDate = _pick(col, row, 'date');
    final desc = _pick(col, row, 'description');
    final merch = _pick(col, row, 'merchant', desc);
    final currency = _pick(col, row, 'currency', currencyFallback);

    final rawAmount = _pick(col, row, 'amount');
    final rawDebit = _pick(col, row, 'debit');
    final rawCredit = _pick(col, row, 'credit');

    final hasAmount = rawAmount.isNotEmpty;
    final hasDebitCredit = rawDebit.isNotEmpty || rawCredit.isNotEmpty;

    // Parse numeric
    final debit = _parseNum(rawDebit);
    final credit = _parseNum(rawCredit);

    final amountParsed =
        rawAmount.trim().isNotEmpty ? _parseNum(rawAmount) : (credit - debit);

// ✅ If user left everything empty, don’t create a 0-amount tx
    if (amountParsed == 0 &&
        rawAmount.trim().isEmpty &&
        rawDebit.trim().isEmpty &&
        rawCredit.trim().isEmpty) {
      throw 'Row has no amount/debit/credit values';
    }

    // Hint direction:
    // - if debit/credit exists → sign is meaningful (credit - debit)
    // - if amount exists and contains negatives → sign is meaningful
    final hintIsIncome = hasDebitCredit
        ? (amountParsed > 0)
        : (hasAmount && amountParsed < 0
            ? false
            : (hasAmount && amountParsed > 0));

    // Resolve CSV category text -> real categoryId
    final rawCat = _pick(col, row, 'category');
    final csvCatId = _resolveCategoryIdFromCsv(rawCat, cats);

    final hasExplicitCategory = csvCatId != null;

    final fallbackCatId = _defaultCategoryId(
      hintIsIncome: hintIsIncome,
      cats: cats,
    );

    final now = DateTime.now();
    final id = const Uuid().v4();

    final tx = TxModel(
      id: id,
      accountId: 'default',
      date: _parseDate(rawDate),
      amount: amountParsed, // raw for now (we will re-sign later)
      currency: currency.isEmpty ? 'USD' : currency,
      merchant: merch.trim(),
      descriptionRaw: desc.trim(),
      categoryId: csvCatId ?? fallbackCatId,
      createdAt: now,
      updatedAt: now,
    );

    return (tx: tx, hasExplicitCategory: hasExplicitCategory);
  }

  /// Commit mapped rows:
  /// 1) parse row
  /// 2) if CSV category mapped -> keep it (DO NOT override by rules)
  /// 3) else apply rules
  /// 4) sign amount by final category.type
  Future<int> commit({
    required List<List<String>> rows,
    required Map<String, int> mapping,
    required String currencyFallback,
  }) async {
    state = const AsyncLoading();
    try {
      ref.read(authUidProvider);

      final repo = ref.read(transactionRepositoryProvider);

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

      if (cats.isEmpty) {
        throw 'No categories found. Please seed categories first.';
      }

      var count = 0;

      for (final r in rows) {
        // 1) base parse
        try {
          final baseRec = _rowToBaseTx(
            col: mapping,
            row: r,
            currencyFallback: currencyFallback,
            cats: cats,
          );

          final base = baseRec.tx;

          final csvCatRaw = _pick(
              mapping, r, 'category'); // if you have helper; else from base
          final csvCatId = _resolveCategoryIdFromCsv(csvCatRaw, cats);

          // If CSV category was valid, keep it.
          // If not, let rules decide.
          final baseForRules = base.copyWith(
            categoryId: csvCatId ?? base.categoryId,
          );

          // 2) apply rules ONLY if CSV didn't map category
          final withCat = baseRec.hasExplicitCategory
              ? baseForRules
              : applyRules(tx: base, rules: rules, categories: cats);

          // 3) sign amount by final category.type (always treat CSV value as ABS)
          final abs = base.amount.abs();
          final signed = _signedAmountFromCategory(
            amountAbs: abs,
            categoryId: withCat.categoryId,
            cats: cats,
          );

          final toSave = withCat.copyWith(
            amount: signed,
            updatedAt: DateTime.now(),
          );

          await repo.upsert(toSave);
          count++;
        } catch (_) {
          continue; // skip bad row
        }
      }

      state = const AsyncData(null);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
