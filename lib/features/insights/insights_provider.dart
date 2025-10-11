import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:mini_finan/features/dashboard/providers.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';

final insightsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(transactionRepositoryProvider);
  final now = DateTime.now();

  final thisStart = DateTime(now.year, now.month, 1);
  final thisEndEx = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  final prevEndEx = thisStart;
  final prevStart = DateTime(thisStart.year, thisStart.month - 1, 1);

  final txs = await repo.watchLatest(limit: 1000).first;

  final thisMonth = txs
      .where((t) => !t.date.isBefore(thisStart) && t.date.isBefore(thisEndEx))
      .toList();
  final prevMonth = txs
      .where((t) => !t.date.isBefore(prevStart) && t.date.isBefore(prevEndEx))
      .toList();

  double totalIncome(List<TxModel> txs) =>
      txs.where((t) => t.amount > 0).fold(0.0, (a, b) => a + b.amount);

  double totalExpense(List<TxModel> txs) =>
      txs.where((t) => t.amount < 0).fold(0.0, (a, b) => a + (-b.amount));

  final incomeThis = totalIncome(thisMonth);
  final incomePrev = totalIncome(prevMonth);
  final expThis = totalExpense(thisMonth);
  final expPrev = totalExpense(prevMonth);

  final nameOf =
      ref.watch(categoryNameLookupProvider).value ?? (String id) => id;

  Map<String, double> byCategory(List<TxModel> txs) {
    final map = <String, double>{};
    for (final t in txs) {
      if (t.amount < 0) {
        map[t.categoryId] = (map[t.categoryId] ?? 0) + (-t.amount);
      }
    }
    return map;
  }

  final byCat = byCategory(thisMonth);
  // ✅ FIXED: Use sorted() with compareTo instead of sortedBy<double>()
  final topCat =
      byCat.entries.sorted((a, b) => b.value.compareTo(a.value)).firstOrNull;
  final topCatName = topCat != null ? nameOf(topCat.key) : null;

  final byMerchant = <String, double>{};
  for (final t in thisMonth) {
    if (t.amount < 0) {
      byMerchant[t.merchant] = (byMerchant[t.merchant] ?? 0) + (-t.amount);
    }
  }
  final topMerchant = byMerchant.entries
      .sorted((a, b) => b.value.compareTo(a.value))
      .firstOrNull
      ?.key;

  final insights = <String>[];

  if (expPrev > 0) {
    final diffPct = ((expThis - expPrev) / expPrev * 100).round();
    if (diffPct.abs() >= 5) {
      if (diffPct > 0) {
        insights.add("📈 You spent $diffPct% more than last month.");
      } else {
        insights.add("📉 You spent ${diffPct.abs()}% less than last month.");
      }
    }
  }

  final netThis = incomeThis - expThis;
  final netPrev = incomePrev - expPrev;
  if (netPrev != 0) {
    final change = ((netThis - netPrev) / netPrev * 100).round();
    if (change > 0) {
      insights.add("💵 You saved $change% more than last month.");
    } else if (change < 0) {
      insights.add("💸 You saved ${change.abs()}% less than last month.");
    }
  }

  if (topCatName != null) {
    insights.add(
        "🍔 Your biggest expense category is $topCatName (\$${topCat?.value.toStringAsFixed(0)}).");
  }

  if (topMerchant != null && topMerchant.trim().isNotEmpty) {
    insights.add("🛍 Your top merchant this month is $topMerchant.");
  }

  return insights.take(3).toList();
});
