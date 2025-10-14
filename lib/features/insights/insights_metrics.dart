import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/dashboard/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';

/// Lightweight view model for insights computation.
class InsightsMetrics {
  InsightsMetrics({
    required this.expenseByCategory, // categoryId -> positive spend
    required this.incomeByCategory, // categoryId -> positive income
    required this.merchantSpend, // merchant -> positive spend
    required this.catNameOf, // resolve categoryId -> name
  });

  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final Map<String, double> merchantSpend;
  final String Function(String id) catNameOf;
}

/// Derive metrics from this month’s transactions. Never throws.
final insightsMetricsProvider = Provider<InsightsMetrics>((ref) {
  final txsAv = ref.watch(txThisMonthProvider);
  final txs = txsAv.value ?? const <TxModel>[];

  final catMap = ref.watch(categoriesMapProvider); // {id: CategoryModel}
  String nameOf(String id) => catMap[id]?.name ?? 'Uncategorized';

  final expByCat = <String, double>{};
  final incByCat = <String, double>{};
  final merchSpend = <String, double>{};

  for (final t in txs) {
    if (t.amount < 0) {
      final v = -t.amount;
      expByCat[t.categoryId] = (expByCat[t.categoryId] ?? 0) + v;
      if (t.merchant.isNotEmpty) {
        merchSpend[t.merchant] = (merchSpend[t.merchant] ?? 0) + v;
      }
    } else if (t.amount > 0) {
      incByCat[t.categoryId] = (incByCat[t.categoryId] ?? 0) + t.amount;
    }
  }

  return InsightsMetrics(
    expenseByCategory: expByCat,
    incomeByCategory: incByCat,
    merchantSpend: merchSpend,
    catNameOf: nameOf,
  );
});
