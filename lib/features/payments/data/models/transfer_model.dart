import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/datetime_converter.dart';

part 'transfer_model.g.dart';

/// Bank-transfer record — `businesses/{b}/transfers/{id}` (web
/// `use-sales.tsx` checkout write + `use-transfers.tsx` schema).
@collection
@JsonSerializable()
class TransferModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String saleId;
  final String? customerId;
  final String? customerName;
  final double amount;
  final double transferFee;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? routingNumber;

  /// `'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'`
  final String status;

  final String? transferId;
  final String? notes;

  @DateTimeConverter()
  final DateTime createdAt;

  @DateTimeConverter()
  final DateTime updatedAt;

  @DateTimeConverter()
  final DateTime? processedAt;

  const TransferModel({
    required this.id,
    required this.businessId,
    required this.saleId,
    this.customerId,
    this.customerName,
    required this.amount,
    this.transferFee = 0.0,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.routingNumber,
    this.status = 'pending',
    this.transferId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  static const List<String> statuses = [
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled',
  ];

  /// Wire format = Firestore Timestamps (web writes `Timestamp.fromDate`).
  static const Set<String> firestoreTimestampFields = {
    'createdAt',
    'updatedAt',
    'processedAt',
  };

  bool get isTerminal => status == 'completed' || status == 'failed';

  factory TransferModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['saleId'] ??= '';
    copy['amount'] = ((copy['amount'] ?? 0.0) as num).toDouble();
    copy['transferFee'] = ((copy['transferFee'] ?? 0.0) as num).toDouble();
    copy['status'] ??= 'pending';
    final now = DateTime.now();

    // createdAt/updatedAt are non-nullable on this model, so the generated
    // fromJson expects ISO strings — normalize Firestore Timestamps first.
    dynamic rawCreated = copy['createdAt'] ?? copy['created_at'];
    if (rawCreated is Timestamp) {
      copy['createdAt'] = rawCreated.toDate().toIso8601String();
    } else if (rawCreated is DateTime) {
      copy['createdAt'] = rawCreated.toIso8601String();
    } else if (rawCreated is! String || rawCreated.isEmpty) {
      copy['createdAt'] = now.toIso8601String();
    }
    dynamic rawUpdated = copy['updatedAt'] ?? copy['updated_at'];
    if (rawUpdated is Timestamp) {
      copy['updatedAt'] = rawUpdated.toDate().toIso8601String();
    } else if (rawUpdated is DateTime) {
      copy['updatedAt'] = rawUpdated.toIso8601String();
    } else if (rawUpdated is! String || rawUpdated.isEmpty) {
      copy['updatedAt'] = copy['createdAt'];
    }

    return _$TransferModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$TransferModelToJson(this);

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
