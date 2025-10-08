import 'dart:developer' as dev;

import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';

TxModel applyRules({
  required TxModel tx,
  required List<RuleModel> rules,
  required List<CategoryModel> categories,
}) {
  final merchant = tx.merchant.toLowerCase();
  final desc = tx.descriptionRaw.toLowerCase();

  for (final r in rules) {
    final hay = (r.field == 'merchant' ? merchant : desc);
    if (hay.contains(r.contains.toLowerCase())) {
      final exists = categories.any((c) => c.id == r.categoryId);
      if (!exists) continue;
      return tx.copyWith(categoryId: r.categoryId);
    }
  }
  return tx;
}
