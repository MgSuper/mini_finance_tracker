import 'package:freezed_annotation/freezed_annotation.dart';
part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TxnType { expense, income }

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required double amount,
    required String category,
    @Default(TxnType.expense) TxnType type,
    DateTime? date,
    String? note,
    String? userId,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
