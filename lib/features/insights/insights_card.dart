import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/insights/insights_ai_provider.dart';
import 'package:mini_finan/features/insights/insights_provider.dart';
import 'package:mini_finan/features/insights/settings_providers.dart';

class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAi = ref.watch(useAiInsightsProvider);
    final aiTextAsync = ref.watch(insightsAiProvider);
    final localAsync = ref.watch(insightsProvider);

    Widget content() {
      if (useAi) {
        return aiTextAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _LocalFallback(localAsync: localAsync),
          data: (aiText) {
            if (aiText == null || aiText.isEmpty) {
              return _LocalFallback(localAsync: localAsync);
            }
            return _AiText(aiText: aiText);
          },
        );
      }
      return _LocalFallback(localAsync: localAsync);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡 Insights',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                // Toggle
                Row(
                  children: [
                    const Text('AI'),
                    const SizedBox(width: 8),
                    Switch(
                      value: useAi,
                      onChanged: (_) =>
                          ref.read(useAiInsightsProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            content(),
          ],
        ),
      ),
    );
  }
}

class _LocalFallback extends StatelessWidget {
  const _LocalFallback({required this.localAsync});
  final AsyncValue<List<String>> localAsync;

  @override
  Widget build(BuildContext context) {
    return localAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading insights: $e'),
      data: (insights) {
        if (insights.isEmpty) {
          return const Text('No insights yet — add more transactions!');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  s,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AiText extends StatelessWidget {
  const _AiText({required this.aiText});
  final String aiText;

  @override
  Widget build(BuildContext context) {
    return Text(
      aiText,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        height: 1.35,
      ),
    );
  }
}
