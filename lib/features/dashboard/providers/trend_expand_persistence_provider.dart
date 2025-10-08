import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/dashboard/providers/expand_prefs.dart';

// Unique keys per section
const _kTrendExpandedKey = 'monthly_trend_expanded';
const _kTopCategoriesExpandedKey = 'top_categories_expanded';
const _kRecentTxExpandedKey = 'recent_tx_expanded';

final monthlyTrendExpandedProvider =
    AsyncNotifierProvider<ExpandSectionNotifier, bool>(
  () => ExpandSectionNotifier(_kTrendExpandedKey),
);

final topCategoriesExpandedProvider =
    AsyncNotifierProvider<ExpandSectionNotifier, bool>(
  () => ExpandSectionNotifier(_kTopCategoriesExpandedKey),
);

final recentTxExpandedProvider =
    AsyncNotifierProvider<ExpandSectionNotifier, bool>(
  () => ExpandSectionNotifier(_kRecentTxExpandedKey),
);
