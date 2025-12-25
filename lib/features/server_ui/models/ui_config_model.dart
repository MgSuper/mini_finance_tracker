import 'package:json_annotation/json_annotation.dart';
import 'package:mini_finan/features/transactions/data/transaction_model.dart';

part 'ui_config_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UiConfigModel {
  final int version;
  @TimestampConverter()
  final DateTime? updatedAt;
  final DashboardConfigModel dashboard;

  UiConfigModel(
      {required this.version, this.updatedAt, required this.dashboard});
  factory UiConfigModel.fromJson(Map<String, dynamic> json) =>
      _$UiConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$UiConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DashboardConfigModel {
  final List<DashboardSectionModel> sections;

  DashboardConfigModel({required this.sections});

  factory DashboardConfigModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DashboardSectionModel {
  final String key;
  final String type;
  final bool? collapsedByDefault;
  final String? mode;
  final int? limit;

  DashboardSectionModel(
      {required this.key,
      required this.type,
      this.collapsedByDefault,
      this.mode,
      this.limit});

  factory DashboardSectionModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardSectionModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardSectionModelToJson(this);
}
