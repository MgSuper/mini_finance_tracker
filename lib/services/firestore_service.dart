import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService(this._db);

  CollectionReference<Map<String, dynamic>> userCol(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Future<void> upsert(
    String path,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await _db.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<void> delete(String path) => _db.doc(path).delete();
}
