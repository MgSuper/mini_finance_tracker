import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/insights/insights_resolved_provider.dart';
import 'package:mini_finan/features/insights/insights_settings.dart';

class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAi = ref.watch(insightsUseAiProvider);
    final insightsAv = ref.watch(monthlyInsightsResolvedProvider);
    debugPrint('[InsightsCard] useAi=$useAi');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('💡 Insights',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('AI', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(width: 8),
                Switch(
                  value: useAi,
                  onChanged: (v) =>
                      ref.read(insightsUseAiProvider.notifier).state = v,
                ),
              ],
            ),
            const SizedBox(height: 8),
            insightsAv.when(
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text('Error loading insights: $e',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              data: (lines) {
                if (lines.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'We’ll show insights once you add more transactions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final line in lines)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(line)),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
