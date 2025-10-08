import 'package:json_annotation/json_annotation.dart';
part 'rule_model.g.dart';

@JsonSerializable()
class RuleModel {
  final String id;
  final String field; // "merchant" or "description"
  final String contains; // lowercase keyword
  final String categoryId;

  RuleModel({
    required this.id,
    required this.field,
    required this.contains,
    required this.categoryId,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json, String id) =>
      _$RuleModelFromJson({...json, 'id': id});

  Map<String, dynamic> toJson() => _$RuleModelToJson(this);
}
