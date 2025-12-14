import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/categories_providers.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';

/// Reactive auth convenience
final isSignedInProvider =
    Provider<bool>((ref) => ref.watch(authUidNullableProvider) != null);

/// "Now" as a single read; invalidate to recompute ranges.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Start (inclusive) and end (exclusive) for the current month, local time.
/// End is the **first day of next month @ 00:00** (exclusive).
final monthRangeProvider = Provider<(DateTime start, DateTime endEx)>((ref) {
  final now = ref.watch(nowProvider);
  final start = DateTime(now.year, now.month, 1);
  final endEx = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return (start, endEx);
});

/// All transactions stream (reactive to auth).
/// When signed out → empty stream (prevents permission-denied flashes).
final transactionsStreamProvider =
    StreamProvider.autoDispose<List<TxModel>>((ref) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) return const Stream<List<TxModel>>.empty();
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchLatest(limit: 500);
});

/// This month’s transactions (in-memory filter; Firestore range can come later).
final txThisMonthProvider = Provider<AsyncValue<List<TxModel>>>((ref) {
  // If signed out, short-circuit to empty list
  final signedIn = ref.watch(isSignedInProvider);
  if (!signedIn) return const AsyncData(<TxModel>[]);

  final all = ref.watch(transactionsStreamProvider);
  final (start, endEx) = ref.watch(monthRangeProvider);

  return all.whenData((list) {
    final filtered = list
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(endEx))
        .toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        // fallbacks: updatedAt, then id
        final byUpdated = b.updatedAt.compareTo(a.updatedAt);
        if (byUpdated != 0) return byUpdated;
        return b.id.compareTo(a.id);
      });
    return filtered;
  });
});

/// Totals for this month: spent (<0 aggregated abs), income (>0), net.
final totalsProvider =
    Provider<AsyncValue<({double spent, double income, double net})>>((ref) {
  final txs = ref.watch(txThisMonthProvider);
  return txs.whenData((list) {
    double income = 0, spentAbs = 0;
    for (final t in list) {
      if (t.amount >= 0) {
        income += t.amount;
      } else {
        spentAbs += -t.amount;
      }
    }
    final net = income - spentAbs;
    return (spent: spentAbs, income: income, net: net);
  });
});

/// Spending by category for this month (expenses only; positive numbers).
final spendByCategoryProvider =
    Provider<AsyncValue<List<({String categoryId, double amount})>>>((ref) {
  final txs = ref.watch(txThisMonthProvider);
  return txs.whenData((list) {
    final map = <String, double>{};
    for (final t in list) {
      if (t.amount < 0) {
        map[t.categoryId] = (map[t.categoryId] ?? 0) + (-t.amount);
      }
    }
    final items = map.entries
        .map((e) => (categoryId: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  });
});

/// Top N categories by spend (ready for UI).
final topCategoriesProvider = Provider.family<
    AsyncValue<List<({String categoryId, double amount})>>, int>((ref, topN) {
  final byCat = ref.watch(spendByCategoryProvider);
  return byCat.whenData((items) => items.take(topN).toList());
});

/// Recent N transactions (already month-filtered & sorted desc).
final recentTxProvider =
    Provider.family<AsyncValue<List<TxModel>>, int>((ref, n) {
  final txs = ref.watch(txThisMonthProvider);
  return txs.whenData((list) => list.take(n).toList());
});

/// Convenience: resolve categoryId -> display name.
/// Safe when signed out / not loaded (returns fallback names).
final categoryNameLookupProvider =
    Provider<AsyncValue<String Function(String)>>((ref) {
  // categoriesMapProvider should already be auth-aware; still provide safe fallback
  final map = ref.watch(categoriesMapProvider);
  return AsyncData((String id) => map[id]?.name ?? 'Uncategorized');
});

/// Resolve categoryId -> color hex (or null).
final categoryColorLookupProvider =
    Provider<AsyncValue<String? Function(String)>>((ref) {
  final map = ref.watch(categoriesMapProvider);
  return AsyncData((String id) => map[id]?.color);
});

/// Total spend (expenses) this month to normalize progress bars.
final totalSpendThisMonthProvider = Provider<AsyncValue<double>>((ref) {
  final byCat = ref.watch(spendByCategoryProvider);
  return byCat.whenData(
    (items) => items.fold<double>(0, (sum, it) => sum + it.amount),
  );
});

/// ---------------------------------------------------------------------------
/// Monthly trend (last 6 months): total net balance per month
/// ---------------------------------------------------------------------------
final monthlyNetTrendProvider =
    Provider<AsyncValue<List<({DateTime month, double net})>>>((ref) {
  final all = ref.watch(transactionsStreamProvider);
  return all.whenData((txs) {
    if (txs.isEmpty) return <({DateTime month, double net})>[];

    final now = DateTime.now();
    final sixMonthsAgo =
        DateTime(now.year, now.month - 5, 1); // include current month

    final byMonth = <DateTime, double>{};

    for (final t in txs) {
      // group key = first day of that month
      final key = DateTime(t.date.year, t.date.month, 1);
      if (key.isBefore(sixMonthsAgo)) continue;
      byMonth[key] = (byMonth[key] ?? 0) + t.amount;
    }

    // sort ascending by month
    final sorted = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted
        .map((e) => (month: e.key, net: e.value))
        .toList(growable: false);
  });
});

// Keep expanded/collapsed state for the monthly trend section.
// final monthlyTrendExpandedProvider = StateProvider<bool>((ref) => false);
