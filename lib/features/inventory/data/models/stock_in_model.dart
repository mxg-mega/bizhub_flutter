import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stock_in_model.g.dart';

@collection
@JsonSerializable(explicitToJson: true)
class StockInModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String supplierId;
  final String supplierName;
  final String locationId;
  
  @ignore
  final List<StockInItem> items;

  /// Local storage representation for Isar
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String itemsJson;
  
  final double totalCost;
  final bool isPaid; // Cash vs Credit purchase
  
  final DateTime timestamp;
  final String? notes;

  StockInModel({
    required this.id,
    required this.businessId,
    required this.supplierId,
    required this.supplierName,
    required this.locationId,
    this.items = const [],
    required this.totalCost,
    this.isPaid = true,
    required this.timestamp,
    this.notes,
  }) : itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());

  factory StockInModel.fromJson(Map<String, dynamic> json) =>
      _$StockInModelFromJson(json);
  Map<String, dynamic> toJson() => _$StockInModelToJson(this);

  int _fastHash(String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}

@embedded
@JsonSerializable()
class StockInItem {
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final double costPrice;

  const StockInItem({
    this.productId = '',
    this.name = '',
    this.quantity = 0.0,
    this.unit = '',
    this.costPrice = 0.0,
  });

  factory StockInItem.fromJson(Map<String, dynamic> json) =>
      _$StockInItemFromJson(json);
  Map<String, dynamic> toJson() => _$StockInItemToJson(this);
}
