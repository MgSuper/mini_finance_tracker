import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TxModel {
  final String id;
  final String accountId;
  @TimestampConverter()
  final DateTime date;
  final double amount;
  final String currency;
  final String merchant;
  final String descriptionRaw;
  final String categoryId;
  @TimestampConverter()
  final DateTime createdAt;
  @TimestampConverter()
  final DateTime updatedAt;

  TxModel({
    required this.id,
    required this.accountId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.descriptionRaw,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  TxModel copyWith({
    String? id,
    String? accountId,
    DateTime? date,
    double? amount,
    String? currency,
    String? merchant,
    String? descriptionRaw,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TxModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      descriptionRaw: descriptionRaw ?? this.descriptionRaw,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TxModel.fromJson(Map<String, dynamic> json) =>
      _$TxModelFromJson(json);
  Map<String, dynamic> toJson() => _$TxModelToJson(this);
}

class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    throw ArgumentError('Invalid date: $json');
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}
