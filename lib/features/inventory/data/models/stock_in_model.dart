import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

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
  
  @DateTimeConverter()
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
  }) : itemsJson = jsonEncode(items.map((final i) => i.toJson()).toList());

  factory StockInModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['supplierId'] ??= copy['supplier_id'] ?? '';
    copy['supplierName'] ??= copy['supplier_name'] ?? 'Supplier';
    copy['locationId'] ??= copy['location_id'] ?? 'main';
    copy['totalCost'] = ((copy['totalCost'] ?? copy['total_cost'] ?? 0.0) as num).toDouble();
    copy['isPaid'] ??= true;

    dynamic rawDate = copy['timestamp'] ?? copy['createdAt'] ?? copy['date'];
    if (rawDate is Timestamp) {
      copy['timestamp'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['timestamp'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['timestamp'] = rawDate;
    } else {
      copy['timestamp'] = DateTime.now().toIso8601String();
    }

    return _$StockInModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$StockInModelToJson(this);

  int _fastHash(final String string) {
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

  factory StockInItem.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['productId'] ??= copy['product_id'] ?? '';
    copy['name'] ??= '';
    copy['quantity'] = ((copy['quantity'] ?? 0.0) as num).toDouble();
    copy['unit'] ??= '';
    copy['costPrice'] = ((copy['costPrice'] ?? copy['cost_price'] ?? 0.0) as num).toDouble();
    return _$StockInItemFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$StockInItemToJson(this);
}
