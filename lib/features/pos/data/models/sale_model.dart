import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'sale_item_model.dart';

part 'sale_model.g.dart';

@collection
@JsonSerializable(explicitToJson: true)
class SaleModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String userId;
  final String? customerId;
  
  @ignore
  final List<SaleItemModel> items;
  
  /// Local storage representation for Isar
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String itemsJson;

  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  
  final String paymentMethod; // cash, card, transfer, on_credit
  final String status; 
  final DateTime timestamp;
  final String locationId;
  final SaleWorkflowModel? workflow;

  SaleModel({
    required this.id,
    required this.businessId,
    required this.userId,
    this.customerId,
    this.items = const [],
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.status = 'Paid',
    required this.timestamp,
    required this.locationId,
    this.workflow,
  }) : itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());

  factory SaleModel.fromJson(final Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleModelToJson(this);

  SaleModel copyWith({
    String? status,
    SaleWorkflowModel? workflow,
  }) {
    return SaleModel(
      id: id,
      businessId: businessId,
      userId: userId,
      customerId: customerId,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp,
      locationId: locationId,
      workflow: workflow ?? this.workflow,
    );
  }

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
class SaleWorkflowModel {
  final bool enabled;
  final String createdBy;
  final String createdByName;
  final String? approvedBy;
  
  @ignore
  final List<SaleWorkflowStage>? history;

  const SaleWorkflowModel({
    this.enabled = false,
    this.createdBy = '',
    this.createdByName = '',
    this.approvedBy,
    this.history,
  });

  factory SaleWorkflowModel.fromJson(Map<String, dynamic> json) =>
      _$SaleWorkflowModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleWorkflowModelToJson(this);
}

@embedded
@JsonSerializable()
class SaleWorkflowStage {
  final String status;
  final DateTime? timestamp; // Optional for Isar
  final String actorId;
  final String? notes;

  const SaleWorkflowStage({
    this.status = '',
    this.timestamp,
    this.actorId = '',
    this.notes,
  });

  factory SaleWorkflowStage.fromJson(Map<String, dynamic> json) =>
      _$SaleWorkflowStageFromJson(json);
  Map<String, dynamic> toJson() => _$SaleWorkflowStageToJson(this);
}
