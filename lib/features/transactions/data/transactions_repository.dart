import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/services/firebase_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return TransactionRepository(db, () => auth.currentUser?.uid);
});

class TransactionRepository {
  TransactionRepository(this._db, this._uid);
  final FirebaseFirestore _db;
  final String? Function() _uid;

  String _requireUid() {
    final uid = _uid();
    if (uid == null) {
      throw StateError('Not signed in');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _requireUid();
    return _db.collection('users').doc(uid).collection('transactions');
  }

  Future<void> upsert(TxModel tx) async {
    await _col().doc(tx.id).set(tx.toJson(), SetOptions(merge: true));
  }

  Stream<List<TxModel>> watchLatest({int limit = 50}) {
    try {
      final c = _col();
      return c.orderBy('date', descending: true).limit(limit).snapshots().map(
            (s) => s.docs
                .map((d) => TxModel.fromJson({...d.data(), 'id': d.id}))
                .toList(),
          );
    } on StateError {
      return const Stream<List<TxModel>>.empty();
    }
  }

  // use later
  Stream<List<TxModel>> watchByDateRange(DateTime start, DateTime end) {
    final c = _col();
    return c
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TxModel.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  Stream<List<TxModel>> watchInRange(DateTime start, DateTime endExclusive) {
    try {
      final c = _col();

      return c
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: endExclusive) // 👈 exclusive
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) {
        for (final d in s.docs) {
          // ignore: avoid_print
          print('tx date=${(d.data()['date'] as Timestamp?)?.toDate()}');
        }
        return s.docs
            .map((d) => TxModel.fromJson({...d.data(), 'id': d.id}))
            .toList();
      });
    } on StateError {
      return const Stream<List<TxModel>>.empty();
    }
  }

  Stream<TxModel?> watchById(String id) {
    try {
      return _col().doc(id).snapshots().map((s) {
        if (!s.exists) return null;
        return TxModel.fromJson({...s.data()!, 'id': s.id});
      });
    } on StateError {
      // signed out → no stream
      return const Stream<TxModel?>.empty();
    }
  }

  Future<TxModel?> getById(String id) async {
    final d = await _col().doc(id).get();
    if (!d.exists) return null;
    return TxModel.fromJson({...d.data()!, 'id': d.id});
  }

  Future<void> delete(String id) async {
    await _col().doc(id).delete();
  }

  // sugar for undo (just calls upsert)
  Future<void> restore(TxModel tx) =>
      upsert(tx.copyWith(updatedAt: DateTime.now()));
}
