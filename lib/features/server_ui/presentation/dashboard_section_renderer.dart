import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mini_finan/features/server_ui/models/ui_config_model.dart';
import 'package:mini_finan/features/server_ui/presentation/widgets/expandable_section_card.dart';

// ✅ Your existing dashboard bits
import 'package:mini_finan/features/dashboard/providers.dart';
import 'package:mini_finan/features/dashboard/providers/trend_expand_persistence_provider.dart';
import 'package:mini_finan/features/dashboard/widgets/monthly_trend_chart.dart';
import 'package:mini_finan/features/insights/insights_card.dart';
import 'package:mini_finan/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:go_router/go_router.dart';

class DashboardSectionRenderer extends ConsumerWidget {
  const DashboardSectionRenderer({super.key, required this.section});

  final DashboardSectionModel section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = section.type.trim().toLowerCase();
    final key = section.key;
    final collapsed = section.collapsedByDefault ?? false;
    print('key $key');
    print('type $type');

    switch (type) {
      case 'totals':
        return ExpandableSectionCard(
          sectionKey: key,
          title: 'Totals',
          defaultCollapsed: collapsed,
          child: _TotalsSection(),
        );

      case 'chart_monthly':
        return ExpandableSectionCard(
          sectionKey: key,
          title: 'Monthly Net Trend',
          defaultCollapsed: collapsed,
          child: const SizedBox(height: 220, child: MonthlyTrendChart()),
        );

      case 'top_categories':
        final limit = (section.limit ?? 5).clamp(1, 20);
        return ExpandableSectionCard(
          sectionKey: key,
          title: 'Top Categories (This Month)',
          defaultCollapsed: collapsed,
          child: _TopCategoriesSection(limit: limit),
        );

      case 'insights':
        return ExpandableSectionCard(
          sectionKey: key,
          title: 'Insights',
          defaultCollapsed: collapsed,
          child: const InsightsCard(),
        );

      case 'recent_transactions':
        final limit = (section.limit ?? 5).clamp(1, 50);
        return ExpandableSectionCard(
          sectionKey: key,
          title: 'Recent Transactions',
          defaultCollapsed: collapsed,
          child: _RecentTxSection(limit: limit),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _TotalsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(totalsProvider);

    return totals.when(
      loading: () => const _TotalsSkeleton(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Error: $e'),
      ),
      data: (v) => _TotalsContent(v: v),
    );
  }
}

class _TotalsSkeleton extends StatelessWidget {
  const _TotalsSkeleton();

  @override
  Widget build(BuildContext context) {
    // Keep your existing skeleton layout if you want.
    // (I’m keeping it simple here; you already have a good skeleton in your file.)
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _TotalsContent extends StatelessWidget {
  const _TotalsContent({required this.v});
  final ({double spent, double income, double net}) v;

  @override
  Widget build(BuildContext context) {
    // Reuse your existing visuals from _TotalsCard data state.
    // If you want identical design, you can literally paste your _TotalsCard(data:) body here.
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (ctx, c) {
        final small = c.maxWidth < 360;
        if (small) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TotalChip(label: 'Income', value: v.income),
                  _TotalChip(label: 'Spent', value: -v.spent, isNegative: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Net', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _money(v.net),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            _TotalChip(label: 'Income', value: v.income),
            const SizedBox(width: 12),
            _TotalChip(label: 'Spent', value: -v.spent, isNegative: true),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Net', style: theme.textTheme.labelMedium),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _money(v.net),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TopCategoriesSection extends ConsumerWidget {
  const _TopCategoriesSection({required this.limit});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep your existing data logic:
    final topCats = ref.watch(topCategoriesProvider(limit));
    final catNameL = ref.watch(categoryNameLookupProvider);
    final catColorL = ref.watch(categoryColorLookupProvider);
    final totalSpend = ref.watch(totalSpendThisMonthProvider);

    return topCats.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
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
        final total = (totalSpend.value ?? 0).clamp(0, double.infinity);

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
    );
  }
}

class _RecentTxSection extends ConsumerWidget {
  const _RecentTxSection({required this.limit});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentTxProvider(limit));

    return recent.when(
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
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
                  final start = DateTime(now.year, now.month, 1);
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
    );
  }
}

/// --- copied helpers from your DashboardScreen (keep identical) ---

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

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
        child: const Icon(Icons.receipt_long, size: 18, color: Colors.white),
      ),
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
  final s = v.toStringAsFixed(2);
  return (v >= 0) ? '+\$ $s' : '-\$${s.replaceFirst('-', '')}';
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6) return null;
  return Color(int.parse('FF$h', radix: 16));
}
