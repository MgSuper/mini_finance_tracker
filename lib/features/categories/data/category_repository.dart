import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final uid = ref.watch(authUidNullableProvider);
  final db = FirebaseFirestore.instance;
  return CategoriesRepository(db, () => uid);
});

class CategoriesRepository {
  CategoriesRepository(this._db, this._uid);
  final FirebaseFirestore _db;
  final String? Function() _uid;

  String _requireUid() {
    final uid = _uid();
    if (uid == null) throw StateError('No user signed in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _requireUid();
    return _db.collection('users').doc(uid).collection('categories');
  }

  Stream<List<CategoryModel>> watchAll() {
    try {
      return _col().orderBy('name').snapshots().map((s) =>
          s.docs.map((d) => CategoryModel.fromJson(d.data(), d.id)).toList());
    } on StateError {
      // signed out → empty
      return const Stream<List<CategoryModel>>.empty();
    }
  }

  Future<void> addCategory({
    required String name,
    required String code,
    required String color,
    required CategoryType type,
  }) async {
    await _col().add({
      'name': name,
      'code': code,
      'color': color,
      'type': type.name, // 👈 use enum.name to avoid _$CategoryTypeEnumMap
    });
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    String? code,
    String? color,
    CategoryType? type,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (code != null) data['code'] = code;
    if (color != null) data['color'] = color;
    if (type != null) data['type'] = type.name; // 👈
    await _col().doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) async {
    await _col().doc(id).delete();
  }
}
