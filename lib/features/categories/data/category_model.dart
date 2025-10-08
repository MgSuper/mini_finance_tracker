import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

/// The two valid types of categories.
/// We use explicit @JsonValue to ensure Firestore consistency.
@JsonEnum(alwaysCreate: true)
enum CategoryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

@JsonSerializable()
class CategoryModel {
  final String id; // Firestore doc id
  final String name; // Human label e.g. "Food & Drink"
  final String code; // Stable slug e.g. "food_drink"
  final String color; // Hex string, e.g. "#FF9800"
  final CategoryType type; // 👈 NEW: 'income' or 'expense'

  CategoryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.type,
  });

  /// Firestore doc → model (id injected manually)
  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) {
    final data = {...json, 'id': id};
    // 🧩 Backward-compatible: default missing type → 'expense'
    data['type'] ??= 'expense';
    return _$CategoryModelFromJson(data);
  }

  /// Model → Firestore
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}
