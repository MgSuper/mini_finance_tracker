import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/insights/insights_ai_provider.dart';
import 'package:mini_finan/features/insights/insights_local_provider.dart';
import 'package:mini_finan/features/insights/insights_settings.dart';

/// Final source used by the card: AI when toggle is ON, else local.
final monthlyInsightsResolvedProvider =
    Provider<AsyncValue<List<String>>>((ref) {
  final useAi = ref.watch(insightsUseAiProvider);
  return useAi
      ? ref.watch(monthlyInsightsAiProvider)
      : AsyncData(ref.watch(monthlyInsightsLocalProvider));
});
