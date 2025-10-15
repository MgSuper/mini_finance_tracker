import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:mini_finan/features/dashboard/providers.dart'; // for nowProvider/categoryNameLookupProvider
import 'package:mini_finan/features/transactions/data/transaction_model.dart';

/// A structured metrics map for "this month" vs "last month".
/// Reactive: recomputes whenever transactions change.
final insightsMetricsProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final txsAsync = ref.watch(transactionsStreamProvider); // live stream
  final now = ref.watch(nowProvider); // so month change re-computes, too

  return txsAsync.whenData((txs) {
    final thisStart = DateTime(now.year, now.month, 1);
    final thisEndEx = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final prevEndEx = thisStart;
    final prevStart = DateTime(thisStart.year, thisStart.month - 1, 1);

    List<TxModel> inRange(DateTime a, DateTime b) =>
        txs.where((t) => !t.date.isBefore(a) && t.date.isBefore(b)).toList();

    final thisMonth = inRange(thisStart, thisEndEx);
    final lastMonth = inRange(prevStart, prevEndEx);

    double incomeOf(List<TxModel> l) =>
        l.where((t) => t.amount > 0).fold(0.0, (s, t) => s + t.amount);

    double expenseOf(List<TxModel> l) =>
        l.where((t) => t.amount < 0).fold(0.0, (s, t) => s + (-t.amount));

    Map<String, double> expensesByCategory(List<TxModel> l) {
      final map = <String, double>{};
      for (final t in l) {
        if (t.amount < 0) {
          map[t.categoryId] = (map[t.categoryId] ?? 0) + (-t.amount);
        }
      }
      return map;
    }

    Map<String, double> expensesByMerchant(List<TxModel> l) {
      final map = <String, double>{};
      for (final t in l) {
        if (t.amount < 0) {
          final key =
              t.merchant.trim().isEmpty ? '(unknown)' : t.merchant.trim();
          map[key] = (map[key] ?? 0) + (-t.amount);
        }
      }
      return map;
    }

    final thisIncome = incomeOf(thisMonth);
    final lastIncome = incomeOf(lastMonth);
    final thisExpense = expenseOf(thisMonth);
    final lastExpense = expenseOf(lastMonth);

    final nameOf =
        ref.watch(categoryNameLookupProvider).value ?? (String id) => id;

    MapEntry<String, double>? topCat(Map<String, double> m) =>
        (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .firstOrNull;

    final thisByCat = expensesByCategory(thisMonth);
    final lastByCat = expensesByCategory(lastMonth);

    final thisTopCat = topCat(thisByCat);
    final lastTopCat = topCat(lastByCat);

    final thisByMerchant = expensesByMerchant(thisMonth);
    final topMerchant = (thisByMerchant.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;

    return {
      'periods': {
        'this': {
          'start': thisStart.toIso8601String(),
          'endEx': thisEndEx.toIso8601String(),
          'income': thisIncome,
          'expense': thisExpense,
          'net': thisIncome - thisExpense,
          'byCategory': thisByCat.map((k, v) => MapEntry(nameOf(k), v)),
        },
        'last': {
          'start': prevStart.toIso8601String(),
          'endEx': prevEndEx.toIso8601String(),
          'income': lastIncome,
          'expense': lastExpense,
          'net': lastIncome - lastExpense,
          'byCategory': lastByCat.map((k, v) => MapEntry(nameOf(k), v)),
        },
      },
      'thisTopCategory': thisTopCat == null
          ? null
          : {
              'name': nameOf(thisTopCat.key),
              'amount': thisTopCat.value,
            },
      'lastTopCategory': lastTopCat == null
          ? null
          : {
              'name': nameOf(lastTopCat.key),
              'amount': lastTopCat.value,
            },
      'topMerchant': topMerchant == null
          ? null
          : {
              'name': topMerchant.key,
              'amount': topMerchant.value,
            },
    };
  });
});
