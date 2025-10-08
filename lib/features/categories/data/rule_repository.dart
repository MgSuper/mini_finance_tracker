import 'package:cloud_firestore/cloud_firestore.dart';
import 'rule_model.dart';

class RuleRepository {
  final CollectionReference<Map<String, dynamic>> col;
  RuleRepository(this.col);

  Stream<List<RuleModel>> watchAll() => col.snapshots().map(
      (s) => s.docs.map((d) => RuleModel.fromJson(d.data(), d.id)).toList());

  Future<void> add(RuleModel r) => col.doc(r.id).set(r.toJson());
  Future<void> update(RuleModel r) => col.doc(r.id).update(r.toJson());
  Future<void> delete(String id) => col.doc(id).delete();
}
