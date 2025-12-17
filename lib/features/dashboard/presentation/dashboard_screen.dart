import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_finan/features/auth/presentation/widgets/accounts_bottom_sheet.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:mini_finan/features/auth/providers/auth_ui_providers.dart';
import 'package:mini_finan/features/dashboard/providers.dart';
import 'package:mini_finan/features/dashboard/providers/trend_expand_persistence_provider.dart';
import 'package:mini_finan/features/dashboard/widgets/expansion_card.dart';
import 'package:mini_finan/features/dashboard/widgets/expansion_card_shimmer.dart';
import 'package:mini_finan/features/dashboard/widgets/monthly_trend_chart.dart';
import 'package:mini_finan/features/insights/insights_card.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:mini_finan/widgets/error_card.dart';
import 'package:mini_finan/widgets/shimmer_box.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(totalsProvider);
    final label = ref.watch(authLabelProvider);

    final uid = ref.watch(authUidNullableProvider);
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          elevation: 0,
          title: const Text('Dashboard'),
        ),
        body: const Center(child: Text('Sign in to see your dashboard.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showAccountsBottomSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'import' => context.push('/import'),
              'categories' => context.push('/categories'),
              'rules' => context.push('/rules'),
              'more' => context.push('/more'),
              _ => null,
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'import',
                child: Text('Import CSV'),
              ),
              PopupMenuItem(
                value: 'categories',
                child: Text('Manage Categories'),
              ),
              PopupMenuItem(
                value: 'rules',
                child: Text('Manage Rules'),
              ),
              PopupMenuItem(
                value: 'more',
                child: Text('More…'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simple way to recompute ranges/totals
          ref.invalidate(nowProvider);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalsCard(totals: totals),
            // Expandable Monthly Trend
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final expandedState = ref.watch(monthlyTrendExpandedProvider);
                final notifier =
                    ref.read(monthlyTrendExpandedProvider.notifier);

                return expandedState.maybeWhen(
                  data: (expanded) => ExpansionCard(
                    title: 'Monthly Net Trend',
                    expanded: expanded,
                    onToggle: notifier.toggle,
                    child:
                        const SizedBox(height: 220, child: MonthlyTrendChart()),
                  ),
                  orElse: () => const ExpansionCardShimmer(),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final expandedState = ref.watch(topCategoriesExpandedProvider);
                final notifier =
                    ref.read(topCategoriesExpandedProvider.notifier);
                final topCats = ref.watch(topCategoriesProvider(5));
                final catNameL = ref.watch(categoryNameLookupProvider);
                final catColorL = ref.watch(categoryColorLookupProvider);
                final totalSpend = ref.watch(totalSpendThisMonthProvider);

                return expandedState.maybeWhen(
                  data: (expanded) => ExpansionCard(
                    title: 'Top Categories (This Month)',
                    expanded: expanded,
                    onToggle: notifier.toggle,
                    child: topCats.when(
                      loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Error: $e'),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No spending yet this month'),
                          );
                        }
                        final nameOf = catNameL.value ?? (String id) => id;
                        final colorOf = catColorL.value ?? (String id) => null;
                        final total =
                            (totalSpend.value ?? 0).clamp(0, double.infinity);

                        return Column(
                          children: [
                            for (final it in items)
                              _CategoryBarRow(
                                name: nameOf(it.categoryId),
                                colorHex: colorOf(it.categoryId),
                                amount: it.amount,
                                fraction: total > 0 ? (it.amount / total) : 0,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  orElse: () => const ExpansionCardShimmer(),
                );
              },
            ),
            const SizedBox(height: 16),
            const InsightsCard(),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final expandedState = ref.watch(recentTxExpandedProvider);
                final notifier = ref.read(recentTxExpandedProvider.notifier);
                final recent = ref.watch(recentTxProvider(5));

                return expandedState.maybeWhen(
                  data: (expanded) => ExpansionCard(
                    title: 'Recent Transactions',
                    expanded: expanded,
                    onToggle: notifier.toggle,
                    child: recent.when(
                      loading: () => const SizedBox(
                          height: 140,
                          child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: $e'),
                      ),
                      data: (list) {
                        if (list.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No transactions yet this month'),
                          );
                        }
                        return Column(
                          children: [
                            for (final t in list) _TxTile(t: t),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final now = DateTime.now();
                                  final start =
                                      DateTime(now.year, now.month, 1);
                                  final endEx = (now.month == 12)
                                      ? DateTime(now.year + 1, 1, 1)
                                      : DateTime(now.year, now.month + 1, 1);
                                  context.push(
                                    '/transactions?start=${start.toIso8601String()}&end=${endEx.toIso8601String()}',
                                  );
                                },
                                child: const Text('View all'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  orElse: () => const ExpansionCardShimmer(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
        // label: const Text('Add transaction'),
      ),
    );
  }
}

class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({required this.totals});
  final AsyncValue<({double spent, double income, double net})> totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return totals.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final small = c.maxWidth < 360;

              if (small) {
                // === Small layout: same structure as data ===
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TotalChipSkeleton(isNegative: false),
                        _TotalChipSkeleton(isNegative: true),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        // "Net" label placeholder
                        ShimmerBox(width: 28, height: 14, borderRadius: 6),
                        Spacer(),
                        // "Net" value placeholder (FittedBox target size)
                        ShimmerBox(width: 120, height: 26, borderRadius: 6),
                      ],
                    ),
                  ],
                );
              }

              // === Wide layout: same structure as data ===
              return const Row(
                children: [
                  _TotalChipSkeleton(isNegative: false),
                  SizedBox(width: 12),
                  _TotalChipSkeleton(isNegative: true),
                  Spacer(),
                  // Net column (label + value)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBox(width: 24, height: 12, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 140, height: 28, borderRadius: 6),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
      error: (e, _) => ErrorCard(
        error: e,
        onRetry: () => ref.invalidate(transactionsStreamProvider),
        onSignIn: () => context.go('/sign-in'),
      ),
      data: (v) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final small = c.maxWidth < 360; // tweak threshold as you like
              if (small) {
                // Stack vertically on narrow screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      // spacing: 12,
                      // runSpacing: 8,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TotalChip(label: 'Income', value: v.income),
                        _TotalChip(
                            label: 'Spent', value: -v.spent, isNegative: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Net',
                            style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        // Avoid overflow of big numbers
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _money(v.net),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Wide layout (your original intent)
              return Row(
                children: [
                  _TotalChip(label: 'Income', value: v.income),
                  const SizedBox(width: 12),
                  _TotalChip(label: 'Spent', value: -v.spent, isNegative: true),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Net',
                          style: Theme.of(context).textTheme.labelMedium),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _money(v.net),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TotalChipSkeleton extends StatelessWidget {
  const _TotalChipSkeleton({this.isNegative = false});
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final color = isNegative
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    // Mirror _TotalChip: same padding + border radius + background tint
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label (Text(label, style: labelSmall))
          ShimmerBox(width: 46, height: 12, borderRadius: 6),
          SizedBox(height: 6),
          // value (Text(_money(...), style: titleMedium))
          ShimmerBox(width: 96, height: 20, borderRadius: 6),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip(
      {required this.label, required this.value, this.isNegative = false});
  final String label;
  final double value;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final color = isNegative
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(_money(value), style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CategoryBarRow extends StatelessWidget {
  const _CategoryBarRow({
    required this.name,
    required this.colorHex,
    required this.amount,
    required this.fraction,
  });

  final String name;
  final String? colorHex;
  final double amount;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(colorHex) ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(name)),
              Text(_money(amount)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends ConsumerWidget {
  const _TxTile({required this.t});
  final TxModel t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameOf =
        ref.watch(categoryNameLookupProvider).value ?? (String id) => id;
    final colorOf =
        ref.watch(categoryColorLookupProvider).value ?? (String id) => null;
    final color = _parseHex(colorOf(t.categoryId));
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: color ?? Colors.grey.shade300,
          child: const Icon(Icons.receipt_long, size: 18, color: Colors.white)),
      title: Text(t.merchant.isEmpty ? '(No merchant)' : t.merchant),
      subtitle: Text(nameOf(t.categoryId)),
      trailing: Text(
        _money(t.amount),
        style: TextStyle(
          color:
              t.amount < 0 ? Theme.of(context).colorScheme.error : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
      // onTap: () => context.go('/transactions'),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TransactionDetailSheet(txId: t.id),
      ),
    );
  }
}

String _money(double v) {
  // super-simple formatting; swap in intl later
  final s = v.toStringAsFixed(2);
  return (v >= 0) ? '+\$ $s' : '-\$${s.replaceFirst('-', '')}';
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6) return null;
  return Color(int.parse('FF$h', radix: 16));
}
