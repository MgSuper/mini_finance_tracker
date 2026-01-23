import 'package:cloud_firestore/cloud_firestore.dart';

class SeedUserDefaultsService {
  final FirebaseFirestore firestore;

  SeedUserDefaultsService(this.firestore);

  Future<void> seedCategoriesIfNeeded(String uid) async {
    final col = firestore.collection('users').doc(uid).collection('categories');

    final snap = await col.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    await col.add({
      'name': 'Food & Drink',
      'code': 'food_drink',
      'color': '#FF9800',
      'type': 'expense',
    });

    await col.add({
      'name': 'Groceries',
      'code': 'groceries',
      'color': '#4CAF50',
      'type': 'expense',
    });

    await col.add({
      'name': 'Transport',
      'code': 'transport',
      'color': '#2196F3',
      'type': 'expense',
    });

    await col.add({
      'name': 'Income',
      'code': 'income',
      'color': '#009688',
      'type': 'income',
    });
  }
}
