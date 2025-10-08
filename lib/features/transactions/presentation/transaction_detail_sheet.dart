import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_finan/features/transactions/transaction_detail_providers.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/dashboard/providers.dart'
    show categoryNameLookupProvider, categoryColorLookupProvider;

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({super.key, required this.txId});
  final String txId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAv = ref.watch(txByIdProvider(txId));
    final nameOf =
        ref.watch(categoryNameLookupProvider).value ?? (String id) => id;
    final colorOf =
        ref.watch(categoryColorLookupProvider).value ?? (String id) => null;

    return txAv.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _SheetWrap(
        child: Text('Error: $e'),
      ),
      data: (tx) {
        if (tx == null) {
          return const _SheetWrap(
              child: Text('This transaction no longer exists.'));
        }

        final catColor = _parseHex(colorOf(tx.categoryId));
        return _SheetWrap(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: catColor ?? Colors.grey.shade300,
                    child: const Icon(Icons.receipt_long,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tx.merchant.isEmpty ? '(No merchant)' : tx.merchant,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    _money(tx.amount),
                    style: TextStyle(
                      color: tx.amount < 0
                          ? Theme.of(context).colorScheme.error
                          : Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              _KV('Category', nameOf(tx.categoryId)),
              _KV('Date', _yyyyMmDd(tx.date)),
              if (tx.descriptionRaw.isNotEmpty) _KV('Note', tx.descriptionRaw),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        /// 1) Dismiss the sheet first
                        Navigator.of(context).pop();
                        // 2) Then navigate to edit screen (microtask avoids using a disposed context)
                        Future.microtask(() {
                          if (!context.mounted) return;
                          context.push('/transactions/add?id=${tx.id}');
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      label: const Text('Delete'),
                      onPressed: () => _deleteWithUndo(context, ref, tx),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteWithUndo(
      BuildContext context, WidgetRef ref, TxModel tx) async {
    final repo = ref.read(transactionRepositoryProvider);
    // Keep snapshot for undo
    final snapshot = tx;

    await repo.delete(tx.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await repo.upsert(snapshot);
          },
        ),
      ),
    );

    Navigator.of(context).maybePop(); // close sheet
  }
}

class _SheetWrap extends StatelessWidget {
  const _SheetWrap({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(k, style: t.bodySmall)),
          const SizedBox(width: 8),
          Expanded(child: Text(v, style: t.bodyMedium)),
        ],
      ),
    );
  }
}

String _yyyyMmDd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _money(double v) {
  final s = v.abs().toStringAsFixed(2);
  return v < 0 ? '-\$${s}' : '+\$ $s';
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6) return null;
  return Color(int.parse('FF$h', radix: 16));
}
