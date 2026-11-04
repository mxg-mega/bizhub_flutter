import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';
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
  final String? customer;
  
  @ignore
  final List<SaleItemModel> items;
  
  /// Local storage representation for Isar
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String itemsJson;

  final double subtotal;
  final double tax;
  final double discount;
  
  @JsonKey(name: 'totalAmount')
  final double totalAmount;

  double get total => totalAmount;
  
  final String paymentMethod; // cash, card, transfer, on_credit
  final String status; 
  
  @DateTimeConverter()
  final DateTime timestamp;

  @DateTimeConverter()
  final DateTime? createdAt;

  final String locationId;
  final SaleWorkflowModel? workflow;
  final String? barcode;
  final String? notes;
  final double? amountPaid;
  final String? salesPerson;
  final String? referenceNumber;

  SaleModel({
    required this.id,
    required this.businessId,
    required this.userId,
    this.customerId,
    this.customer,
    this.items = const [],
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    this.status = 'Paid',
    required this.timestamp,
    this.createdAt,
    required this.locationId,
    this.workflow,
    this.barcode,
    this.notes,
    this.amountPaid,
    this.salesPerson,
    this.referenceNumber,
  })  : itemsJson = jsonEncode(items.map((final i) => i.toJson()).toList());

  factory SaleModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);

    // Defensive ID & businessId mapping
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['userId'] ??= copy['user_id'] ?? copy['createdBy'] ?? '';
    copy['customerId'] ??= copy['customer_id'];
    copy['customer'] ??= copy['customerName'];
    copy['locationId'] ??= copy['location_id'] ?? 'main';
    copy['paymentMethod'] ??= copy['payment_method'] ?? 'cash';
    copy['status'] ??= 'Paid';

    // Financial mapping
    final total = (copy['totalAmount'] ?? copy['total'] ?? 0.0) as num;
    copy['totalAmount'] = total.toDouble();
    copy['subtotal'] = ((copy['subtotal'] ?? total) as num).toDouble();
    copy['tax'] = ((copy['tax'] ?? 0.0) as num).toDouble();
    copy['discount'] = ((copy['discount'] ?? 0.0) as num).toDouble();

    // Timestamp & date normalization
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

    if (copy['createdAt'] is Timestamp) {
      copy['createdAt'] = (copy['createdAt'] as Timestamp).toDate().toIso8601String();
    }

    return _$SaleModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$SaleModelToJson(this);

  SaleModel copyWith({
    final String? status,
    final SaleWorkflowModel? workflow,
    final double? amountPaid,
  }) {
    return SaleModel(
      id: id,
      businessId: businessId,
      userId: userId,
      customerId: customerId,
      customer: customer,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp,
      createdAt: createdAt,
      locationId: locationId,
      workflow: workflow ?? this.workflow,
      barcode: barcode,
      notes: notes,
      amountPaid: amountPaid ?? this.amountPaid,
      salesPerson: salesPerson,
      referenceNumber: referenceNumber,
    );
  }

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

  factory SaleWorkflowModel.fromJson(final Map<String, dynamic> json) =>
      _$SaleWorkflowModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleWorkflowModelToJson(this);
}

@embedded
@JsonSerializable()
class SaleWorkflowStage {
  final String status;
  final DateTime? timestamp;
  final String actorId;
  final String? notes;

  const SaleWorkflowStage({
    this.status = '',
    this.timestamp,
    this.actorId = '',
    this.notes,
  });

  factory SaleWorkflowStage.fromJson(final Map<String, dynamic> json) =>
      _$SaleWorkflowStageFromJson(json);
  Map<String, dynamic> toJson() => _$SaleWorkflowStageToJson(this);
}
