import 'package:json_annotation/json_annotation.dart';

part 'inventory_adjustment_model.g.dart';

@JsonSerializable()
class InventoryAdjustmentModel {
  final String id;
  @JsonKey(name: 'productId')
  final String productId;
  
  final String type;
  
  final Map<String, Map<String, double>> changes;
  
  final DateTime timestamp;
  
  @JsonKey(name: 'userId')
  final String userId;
  
  final String? reason;

  const InventoryAdjustmentModel({
    required this.id,
    required this.productId,
    required this.type,
    required this.changes,
    required this.timestamp,
    required this.userId,
    this.reason,
  });

  factory InventoryAdjustmentModel.fromJson(final Map<String, dynamic> json) =>
      _$InventoryAdjustmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryAdjustmentModelToJson(this);
}
