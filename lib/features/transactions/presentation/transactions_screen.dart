import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';

import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/providers.dart'; // <- where txFilterProvider & txRangeStreamProvider live

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    this.start, // inclusive
    this.end, // exclusive
  });

  /// Optional initial range from URL:
  /// /transactions?start=...&end=...
  final DateTime? start;
  final DateTime? end;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    // Seed filter from URL once, *after* first frame to avoid "modify during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noti = ref.read(txFilterProvider.notifier);
      if (widget.start != null && widget.end != null) {
        noti.state = (widget.start!, widget.end!);
      } else {
        // Default to "This month"
        noti.state = _thisMonth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gate by auth: show friendly prompt if signed out
    final uid = ref.watch(authUidNullableProvider);
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transactions')),
        body: const Center(child: Text('Sign in to see your transactions.')),
      );
    }

    final range = ref.watch(txFilterProvider);
    final txs = ref.watch(txRangeStreamProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Add',
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(range: range, onPickCustom: _pickCustomRange),
          const Divider(height: 1),
          Expanded(
            child: txs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No transactions in selected range'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _TxTile(t: list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final (start, endEx) = ref.read(txFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015, 1, 1),
      lastDate: DateTime(2100, 1, 1),
      initialDateRange: DateTimeRange(
        start: start,
        end: endEx
            .subtract(const Duration(days: 1)), // show inclusive end in picker
      ),
    );
    if (picked != null) {
      final s =
          DateTime(picked.start.year, picked.start.month, picked.start.day);
      final eEx = DateTime(picked.end.year, picked.end.month, picked.end.day)
          .add(const Duration(days: 1)); // convert to exclusive end
      ref.read(txFilterProvider.notifier).state = (s, eEx);
    }
  }
}

/// --- Filter bar -------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.range,
    required this.onPickCustom,
  });

  final (DateTime start, DateTime endEx) range;
  final Future<void> Function(BuildContext) onPickCustom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThis = _isSameTuple(range, _thisMonth());
    final isLast = _isSameTuple(range, _lastMonth());

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('This month'),
              selected: isThis,
              onSelected: (_) =>
                  ref.read(txFilterProvider.notifier).state = _thisMonth(),
            ),
            FilterChip(
              label: const Text('Last month'),
              selected: isLast,
              onSelected: (_) =>
                  ref.read(txFilterProvider.notifier).state = _lastMonth(),
            ),
            ActionChip(
              label: const Text('Custom…'),
              onPressed: () => onPickCustom(context),
            ),
            const SizedBox(width: 8),
            _RangeBadge(range: range),
          ],
        ),
      ),
    );
  }
}

class _RangeBadge extends StatelessWidget {
  const _RangeBadge({required this.range});
  final (DateTime start, DateTime endEx) range;

  @override
  Widget build(BuildContext context) {
    final (s, eEx) = range;
    final eIncl = eEx.subtract(const Duration(days: 1));
    final label = '${_ymd(s)} → ${_ymd(eIncl)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

/// --- Tiles ------------------------------------------------------------------

class _TxTile extends StatelessWidget {
  const _TxTile({required this.t});
  final TxModel t;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(t.merchant.isEmpty ? '(No merchant)' : t.merchant),
      subtitle: Text(_ymd(t.date)),
      trailing: Text(
        _money(t.amount),
        style: TextStyle(
          color:
              t.amount < 0 ? Theme.of(context).colorScheme.error : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// --- Helpers ----------------------------------------------------------------

String _pad2(int n) => n < 10 ? '0$n' : '$n';

String _ymd(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

String _money(double v) {
  final s = v.toStringAsFixed(2);
  return (v >= 0) ? '+\$ $s' : '-\$${s.replaceFirst('-', '')}';
}

(DateTime, DateTime) _thisMonth() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final endEx = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return (start, endEx);
}

(DateTime, DateTime) _lastMonth() {
  final now = DateTime.now();
  final prev = DateTime(now.year, now.month - 1, 1);
  final start = DateTime(prev.year, prev.month, 1);
  final endEx = DateTime(prev.year, prev.month + 1, 1);
  return (start, endEx);
}

bool _isSameTuple((DateTime, DateTime) a, (DateTime, DateTime) b) {
  return a.$1.year == b.$1.year &&
      a.$1.month == b.$1.month &&
      a.$1.day == b.$1.day &&
      a.$2.year == b.$2.year &&
      a.$2.month == b.$2.month &&
      a.$2.day == b.$2.day;
}
