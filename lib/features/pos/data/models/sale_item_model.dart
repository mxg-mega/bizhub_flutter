import 'package:json_annotation/json_annotation.dart';

part 'sale_item_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double? unitCost;
  final String? category;
  final double totalPrice;

  /// Line-item subtitle/specification (web `SaleItem.description`).
  final String? description;

  /// Web `SaleItem.itemType`: `'product' | 'service' | 'fee' | 'custom'`.
  final String? itemType;

  /// Web `SaleItem.isCustom`: non-catalog line item (no stock lookup).
  final bool? isCustom;

  const SaleItemModel({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.unitCost,
    this.category,
    final double? totalPrice,
    this.description,
    this.itemType,
    this.isCustom,
  }) : totalPrice = totalPrice ?? (quantity * unitPrice);

  /// Mirrors the web's `isInventoryProduct` guard (use-sales.tsx:33): custom
  /// charges, services, and fees must never trigger product reads or stock
  /// mutations.
  bool get isInventory {
    if (isCustom == true) return false;
    if (itemType != null && itemType != 'product') return false;
    if (productId.isEmpty || productId.startsWith('custom_')) return false;
    return true;
  }

  factory SaleItemModel.fromJson(final Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    final price = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final total = (json['totalPrice'] as num?)?.toDouble() ?? (qty * price);

    return SaleItemModel(
      productId: (json['productId'] ?? json['product_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      quantity: qty,
      unit: (json['unit'] ?? '') as String,
      unitPrice: price,
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      category: json['category'] as String?,
      totalPrice: total,
      description: json['description'] as String?,
      itemType: json['itemType'] as String?,
      isCustom: json['isCustom'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);
}
