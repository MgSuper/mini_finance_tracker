import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/insights/insights_metrics.dart';

/// Short bullet points generated locally.
/// Falls back gracefully when not enough data.
final insightsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final m = ref.watch(insightsMetricsProvider);

  return m.whenData((mm) {
    final thisPeriod = mm['periods']['this'] as Map<String, dynamic>;
    final byCat = (thisPeriod['byCategory'] as Map).cast<String, double>();

    // Biggest category
    MapEntry<String, double>? biggest;
    if (byCat.isNotEmpty) {
      final sorted = byCat.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      biggest = sorted.first;
    }

    // Top merchant
    final topMerchant = mm['topMerchant'] as Map<String, dynamic>?;
    final out = <String>[];

    if (biggest != null) {
      out.add(
        'Your biggest expense category is ${biggest.key} '
        '(\$${biggest.value.toStringAsFixed(0)}).',
      );
    }
    if (topMerchant != null) {
      out.add('Your top merchant this month is ${topMerchant['name']}.');
    }

    return out;
  });
});
