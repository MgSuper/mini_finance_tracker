import 'package:mini_finan/features/categories/data/category_model.dart';
import 'package:mini_finan/features/categories/data/rule_model.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';
import 'package:mini_finan/features/transactions/logic/rule_engine.dart';

enum ResolvedSource { csv, rule, fallback }

class ImportPreviewRow {
  ImportPreviewRow({
    required this.date,
    required this.merchant,
    required this.amountRaw,
    required this.csvCategoryRaw,
    required this.resolvedCategoryName,
    required this.source,
  });

  final DateTime date;
  final String merchant;
  final double amountRaw;
  final String csvCategoryRaw;
  final String resolvedCategoryName;
  final ResolvedSource source;
}

List<ImportPreviewRow> buildImportPreview({
  required List<TxModel> baseTxs,
  required List<List<String>> rawRows,
  required Map<String, int> mapping,
  required List<RuleModel> rules,
  required List<CategoryModel> cats,
  required String Function(String id) catNameOf,
  required String? Function(String raw) resolveCategoryIdFromCsv,
  required String fallbackCategoryId,
}) {
  String pick(List<String> row, String key) {
    final i = mapping[key] ?? -1;
    if (i < 0 || i >= row.length) return '';
    return row[i].trim();
  }

  final out = <ImportPreviewRow>[];

  for (int i = 0; i < baseTxs.length; i++) {
    final base = baseTxs[i];
    final raw = rawRows[i];
    final csvRaw = pick(raw, 'category');

    final csvCatId = resolveCategoryIdFromCsv(csvRaw);
    TxModel resolved = base;
    ResolvedSource src = ResolvedSource.fallback;

    if (csvCatId != null) {
      resolved = base.copyWith(categoryId: csvCatId);
      src = ResolvedSource.csv;
    } else {
      final ruled = applyRules(tx: base, rules: rules, categories: cats);
      if (ruled.categoryId != base.categoryId) {
        resolved = ruled;
        src = ResolvedSource.rule;
      } else {
        resolved = base.copyWith(categoryId: fallbackCategoryId);
        src = ResolvedSource.fallback;
      }
    }

    out.add(
      ImportPreviewRow(
        date: base.date,
        merchant: base.merchant,
        amountRaw: base.amount,
        csvCategoryRaw: csvRaw.isEmpty ? '—' : csvRaw,
        resolvedCategoryName: catNameOf(resolved.categoryId),
        source: src,
      ),
    );
  }

  return out;
}
