import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:mini_finan/features/insights/insights_metrics.dart';

/// Pure local summaries. Returns [] when there isn’t enough data.
final monthlyInsightsLocalProvider = Provider<List<String>>((ref) {
  final m = ref.watch(insightsMetricsProvider);

  // maxBy returns null on empty iterables
  final biggestExpense = maxBy(m.expenseByCategory.entries, (e) => e.value);
  final topMerchant = maxBy(m.merchantSpend.entries, (e) => e.value);

  final out = <String>[];
  if (biggestExpense != null) {
    out.add(
      'Your biggest expense category is '
      '${m.catNameOf(biggestExpense.key)} '
      '(\$${biggestExpense.value.toStringAsFixed(0)}).',
    );
  }
  if (topMerchant != null) {
    out.add('Your top merchant this month is ${topMerchant.key}.');
  }
  return out;
});
