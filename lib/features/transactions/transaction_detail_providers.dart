import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/transactions/data/transactions_repository.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';

/// Stream a single transaction by id (null if missing/deleted)
final txByIdProvider = StreamProvider.family<TxModel?, String>((ref, id) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchById(id);
});
