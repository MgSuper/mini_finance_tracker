import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers.dart';
import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/category_repository.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/categories/data/rule_repository.dart';
import 'package:mini_finan/services/firebase_providers.dart';

// All categories as a stream. If signed-out -> empty stream (no crash, no permission error).
final categoriesProvider =
    StreamProvider.autoDispose<List<CategoryModel>>((ref) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) return const Stream<List<CategoryModel>>.empty();

  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchAll(); // your repository stream
});

// Convenience: id -> CategoryModel map (safe when signed-out)
final categoriesMapProvider = Provider<Map<String, CategoryModel>>((ref) {
  final cats = ref.watch(categoriesProvider);
  return cats.maybeWhen(
    data: (list) => {for (final c in list) c.id: c},
    orElse: () => const {},
  );
});
// final categoryRepositoryProvider = Provider((ref) {
//   final uid = ref.watch(authUidProvider);
//   return CategoryRepository(FirebaseFirestore.instance
//       .collection('users')
//       .doc(uid)
//       .collection('categories'));
// });

/// Repository is nullable when signed out (so no crash).
final ruleRepositoryProvider = Provider<RuleRepository?>((ref) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) return null;

  // Prefer your shared firestoreProvider if you have it
  final db = ref.watch(firestoreProvider); // or FirebaseFirestore.instance
  final col = db.collection('users').doc(uid).collection('rules');
  return RuleRepository(col);
});

/// Stream of rules. Signed out => empty stream.
final rulesProvider = StreamProvider.autoDispose<List<RuleModel>>((ref) {
  final repo = ref.watch(ruleRepositoryProvider);
  if (repo == null) return const Stream<List<RuleModel>>.empty();
  return repo.watchAll();
});
