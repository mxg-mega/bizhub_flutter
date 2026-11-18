import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';
import '../../../../core/utils/payment_method.dart';
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

  /// Tax rate stored as a PERCENTAGE (e.g. 10 for 10%) to match the web
  /// contract (`Sale.taxRate` — see docs/PORTING_GUIDE.md §3.1).
  final double taxRate;

  final double discount;

  /// `'percentage' | 'fixed'` — web contract field.
  final String discountType;

  @JsonKey(name: 'totalAmount')
  final double totalAmount;

  double get total => totalAmount;

  final String paymentMethod; // cash, card, bank_transfer, on_credit, other
  final String status;

  /// Wire format: ISO 8601 string (web writes `now.toISOString()`).
  /// Never convert this to a Firestore Timestamp — the web installment
  /// sorter does `new Date(sale.date)` on raw doc data.
  @DateTimeConverter()
  final DateTime date;

  /// Wire format: Firestore Timestamp.
  @DateTimeConverter()
  final DateTime? createdAt;

  /// Wire format: Firestore Timestamp.
  @DateTimeConverter()
  final DateTime? updatedAt;

  final String locationId;

  /// Flat web-contract workflow flag (replaces the legacy nested `workflow`).
  final bool workflowEnabled;

  /// Flat web-contract audit trail
  /// (`[{stage, performedBy, performedByName, performedAt, notes}]`).
  final List<SaleWorkflowStage>? workflowHistory;

  final String? createdBy;
  final String? createdByName;
  final String? approvedBy;
  final String? approvedByName;

  @DateTimeConverter()
  final DateTime? approvedAt;
  final TransferDetailsModel? transferDetails;
  final String? barcode;
  final String? notes;
  final double? amountPaid;
  final String? salesPerson;
  final String? referenceNumber;

  /// Legacy nested workflow object — kept for reading pre-M1 local/doc data
  /// only. Never written to Firestore (`includeToJson: false`); use the flat
  /// [workflowEnabled] / [workflowHistory] / [createdBy]… fields instead.
  @Deprecated('Use flat web-contract workflow fields.')
  @JsonKey(includeToJson: false)
  final SaleWorkflowModel? workflow;

  /// Firestore Timestamp-typed fields for the Sale contract
  /// (docs/PORTING_GUIDE.md §2). Passed to
  /// `FirestoreService.sanitizeForFirestore` when writing the sale document.
  /// `date` is intentionally NOT here: the web writes it as an ISO string.
  static const Set<String> firestoreTimestampFields = {
    'createdAt',
    'updatedAt',
    'approvedAt',
    'performedAt',
    'refundRequestedAt',
    'refundApprovedAt',
    'archivedAt',
  };

  SaleModel({
    required this.id,
    required this.businessId,
    required this.userId,
    this.customerId,
    this.customer,
    this.items = const [],
    required this.subtotal,
    required this.tax,
    this.taxRate = 0.0,
    required this.discount,
    this.discountType = 'fixed',
    required this.totalAmount,
    required this.paymentMethod,
    this.status = 'Paid',
    required this.date,
    this.createdAt,
    this.updatedAt,
    required this.locationId,
    this.workflowEnabled = false,
    this.workflowHistory,
    this.createdBy,
    this.createdByName,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.transferDetails,
    this.barcode,
    this.notes,
    this.amountPaid,
    this.salesPerson,
    this.referenceNumber,
    @Deprecated('Use flat web-contract workflow fields.') this.workflow,
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

    // Canonical payment method (tolerates 'bank transfer' / 'transfer' legacy
    // values — docs/PORTING_GUIDE.md §4).
    copy['paymentMethod'] =
        normalizePaymentMethod(copy['paymentMethod'] ?? copy['payment_method']);

    // Status default depends on the payment method: a credit sale with no
    // status reads back as 'Pending'.
    copy['status'] ??= copy['paymentMethod'] == kPaymentMethodOnCredit
        ? 'Pending'
        : 'Paid';

    // Financial mapping
    final total = (copy['totalAmount'] ?? copy['total'] ?? 0.0) as num;
    copy['totalAmount'] = total.toDouble();
    copy['subtotal'] = ((copy['subtotal'] ?? total) as num).toDouble();
    copy['tax'] = ((copy['tax'] ?? 0.0) as num).toDouble();
    copy['discount'] = ((copy['discount'] ?? 0.0) as num).toDouble();
    copy['taxRate'] = ((copy['taxRate'] ?? 0.0) as num).toDouble();
    copy['discountType'] ??= 'fixed';

    // Backward compatibility: lift the legacy nested `workflow` object
    // (pre-M1 Flutter shape) into the flat web-contract fields. Flat values
    // always win when both are present.
    final legacyWorkflow = copy['workflow'];
    if (legacyWorkflow is Map) {
      copy['workflowEnabled'] ??= legacyWorkflow['enabled'] ?? false;
      copy['createdBy'] ??= legacyWorkflow['createdBy'];
      copy['createdByName'] ??= legacyWorkflow['createdByName'];
      copy['approvedBy'] ??= legacyWorkflow['approvedBy'];
      copy['workflowHistory'] ??= legacyWorkflow['history'];
    }

    // Keep reading legacy timestamp records while writing the date property.
    final rawDate = copy['date'] ?? copy['timestamp'] ?? copy['createdAt'];
    if (rawDate is Timestamp) {
      copy['date'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['date'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['date'] = rawDate;
    } else {
      copy['date'] = DateTime.now().toIso8601String();
    }
    copy['createdAt'] ??= copy['date'];
    if (copy['createdAt'] is Timestamp) {
      copy['createdAt'] =
          (copy['createdAt'] as Timestamp).toDate().toIso8601String();
    }

    return _$SaleModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$SaleModelToJson(this);

  SaleModel copyWith({
    final String? status,
    final double? taxRate,
    final String? discountType,
    final DateTime? updatedAt,
    final bool? workflowEnabled,
    final List<SaleWorkflowStage>? workflowHistory,
    final String? createdBy,
    final String? createdByName,
    final String? approvedBy,
    final String? approvedByName,
    final DateTime? approvedAt,
    final TransferDetailsModel? transferDetails,
    final String? barcode,
    final String? paymentMethod,
    final String? notes,
    final String? referenceNumber,
    final String? salesPerson,
    final String? locationId,
    final String? customerId,
    final String? customer,
    final List<SaleItemModel>? items,
    final double? subtotal,
    final double? tax,
    final double? discount,
    final double? totalAmount,
    final double? amountPaid,
    final DateTime? date,
    final DateTime? createdAt,
  }) {
    return SaleModel(
      id: id,
      businessId: businessId,
      userId: userId,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationId: locationId ?? this.locationId,
      workflowEnabled: workflowEnabled ?? this.workflowEnabled,
      workflowHistory: workflowHistory ?? this.workflowHistory,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      transferDetails: transferDetails ?? this.transferDetails,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      amountPaid: amountPaid ?? this.amountPaid,
      salesPerson: salesPerson ?? this.salesPerson,
      referenceNumber: referenceNumber ?? this.referenceNumber,
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
class TransferDetailsModel {
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? routingNumber;

  @JsonKey(name: 'transferFee')
  final double transferFee;

  final String? transferId;

  /// `'pending' | 'completed' | 'failed'`
  final String status;

  const TransferDetailsModel({
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.routingNumber,
    this.transferFee = 0.0,
    this.transferId,
    this.status = 'pending',
  });

  factory TransferDetailsModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['transferFee'] =
        ((copy['transferFee'] ?? 0.0) as num).toDouble();
    return _$TransferDetailsModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$TransferDetailsModelToJson(this);
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
  /// The [SaleModel.status] value this stage transitioned to.
  /// Web contract field name (`SaleWorkflowStage.stage`).
  final String stage;

  final String performedBy;
  final String performedByName;

  @DateTimeConverter()
  final DateTime? performedAt;

  final String? notes;

  const SaleWorkflowStage({
    this.stage = '',
    this.performedBy = '',
    this.performedByName = '',
    this.performedAt,
    this.notes,
  });

  factory SaleWorkflowStage.fromJson(final Map<String, dynamic> json) {
    // Backward compatibility with the legacy Flutter-only stage shape
    // ({status, actorId, createdAt}) written before M1.
    final copy = Map<String, dynamic>.from(json);
    copy['stage'] ??= copy['status'];
    copy['performedBy'] ??= copy['actorId'];
    copy['performedAt'] ??= copy['createdAt'];
    return _$SaleWorkflowStageFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$SaleWorkflowStageToJson(this);
}
