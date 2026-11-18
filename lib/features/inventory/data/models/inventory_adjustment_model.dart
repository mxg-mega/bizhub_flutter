import 'package:json_annotation/json_annotation.dart';

part 'inventory_adjustment_model.g.dart';

/// Wire contract (docs/PORTING_GUIDE.md §3.6): the web writes
/// `{productId, productName, changes, timestamp (ISO string), userId,
/// type: 'adjustment', notes}` — note `timestamp` is an ISO string, NOT a
/// Firestore Timestamp, and `type` is always the constant 'adjustment'.
@JsonSerializable()
class InventoryAdjustmentModel {
  final String id;
  @JsonKey(name: 'productId')
  final String productId;

  /// Display name of the product at adjustment time (web writes this; used by
  /// history views so the doc survives product deletion).
  final String? productName;

  /// Web constant: always 'adjustment' on the wire.
  final String type;

  /// Flutter-only semantic kind ('sale' | 'transfer' | 'correction' | ...).
  /// Additive field — web ignores unknown keys.
  final String? kind;

  final Map<String, Map<String, double>> changes;

  final DateTime timestamp;

  @JsonKey(name: 'userId')
  final String userId;

  final String? reason;

  final String? notes;

  /// No field of this document is a Firestore Timestamp on the wire —
  /// `timestamp` must remain an ISO string (web parses it with `new Date`).
  static const Set<String> firestoreTimestampFields = {};

  const InventoryAdjustmentModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    this.kind,
    required this.changes,
    required this.timestamp,
    required this.userId,
    this.reason,
    this.notes,
  });

  factory InventoryAdjustmentModel.fromJson(final Map<String, dynamic> json) =>
      _$InventoryAdjustmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryAdjustmentModelToJson(this);
}
