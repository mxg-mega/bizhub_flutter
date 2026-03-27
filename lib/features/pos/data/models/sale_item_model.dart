import 'package:json_annotation/json_annotation.dart';

part 'sale_item_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  const SaleItemModel({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SaleItemModel.fromJson(final Map<String, dynamic> json) =>
      _$SaleItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);
}
