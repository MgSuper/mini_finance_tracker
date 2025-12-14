import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:uuid/uuid.dart';

class DateRange {
  final DateTime start; // inclusive
  final DateTime endExclusive; // exclusive
  const DateRange(this.start, this.endExclusive);
}

// null = no filter (show latest/all)
final selectedRangeProvider = StateProvider<DateRange?>((_) => null);

final filteredTransactionsProvider =
    StreamProvider.autoDispose<List<TxModel>>((ref) {
  ref.watch(authUidProvider); // guard

  final repo = ref.watch(transactionRepositoryProvider);
  final range = ref.watch(selectedRangeProvider);

  if (range != null) {
    return repo.watchInRange(range.start, range.endExclusive);
  }
  return repo.watchLatest(limit: 500);
});

final transactionsProvider =
    StreamProvider.family<List<TxModel>, (DateTime?, DateTime?)>((ref, range) {
  final auth = ref.watch(authStateChangesProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream<List<TxModel>>.empty();
      final repo = ref.watch(transactionRepositoryProvider);
      final (start, end) = range;
      if (start != null && end != null) {
        return repo.watchInRange(start, end);
      } else {
        return repo.watchLatest(limit: 50);
      }
    },
    loading: () => const Stream<List<TxModel>>.empty(),
    error: (_, __) => const Stream<List<TxModel>>.empty(),
  );
});

final seedTxProvider = Provider((ref) => SeedTx(ref));

class SeedTx {
  SeedTx(this._ref);
  final Ref _ref;

  Future<void> addSample() async {
    final repo = _ref.read(transactionRepositoryProvider);
    final id = const Uuid().v4();
    final now = DateTime.now();
    final tx = TxModel(
      id: id,
      accountId: 'demo',
      date: now,
      amount: -4.50,
      currency: 'USD',
      merchant: 'Coffee Bar',
      descriptionRaw: 'Latte',
      categoryId: 'food_drink',
      createdAt: now,
      updatedAt: now,
    );
    await repo.upsert(tx);
  }
}

/// Global date filter state for Transactions screen.
/// Default = "This month" range (inclusive start, exclusive end)
final txFilterProvider = StateProvider<(DateTime start, DateTime endEx)>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final endEx = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return (start, endEx);
});

/// ---------------------------------------------------------------------------
/// RANGE STREAM PROVIDER
/// ---------------------------------------------------------------------------

/// Watch transactions within a given date range from Firestore.
/// Safe for signed-out users (empty stream).
final txRangeStreamProvider = StreamProvider.family
    .autoDispose<List<TxModel>, (DateTime start, DateTime endEx)>((ref, range) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) return const Stream<List<TxModel>>.empty();

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchInRange(range.$1, range.$2);
});
