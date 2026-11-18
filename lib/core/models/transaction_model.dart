import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/datetime_converter.dart';

part 'transaction_model.g.dart';

enum FinancialCategory {
  @JsonValue('revenue')
  revenue,
  @JsonValue('cogs')
  cogs, // Cost of Goods Sold
  @JsonValue('opex')
  opex, // Operating Expenses
  @JsonValue('asset')
  asset,
  @JsonValue('liability')
  liability,
  @JsonValue('equity')
  equity,
  @JsonValue('other_income')
  otherIncome,
  @JsonValue('other_expense')
  otherExpense,
}

@collection
@JsonSerializable()
class TransactionModel {
  Id get isarId => _fastHash(id);

  /// Canonical ledger `type` values on the Firestore wire (docs/PORTING_GUIDE.md §3.4).
  /// Web writes only 'Sale' and 'Customer Payment' today; the rest are reserved.
  /// 'Transfer' is a Flutter-only extension.
  static const Set<String> canonicalTypes = {
    'Sale',
    'Expense',
    'Customer Payment',
    'Refund',
    'Adjustment',
    'Transfer',
  };

  /// Fields that must be Firestore Timestamps on the wire (§2). `date` is the
  /// web ledger's ordering field (`orderBy('date')`) — docs without it are
  /// silently dropped from web queries.
  static const Set<String> firestoreTimestampFields = {'date', 'createdAt'};

  /// Maps legacy/misspelled types to the canonical set (§4):
  /// 'income'/'sale' → 'Sale', 'expenses' → 'Expense', case-insensitive.
  static String normalizeType(final String? raw) {
    if (raw == null) return 'Sale';
    switch (raw.trim().toLowerCase()) {
      case 'sale':
      case 'income':
        return 'Sale';
      case 'expense':
      case 'expenses':
        return 'Expense';
      case 'customer payment':
        return 'Customer Payment';
      case 'refund':
        return 'Refund';
      case 'adjustment':
        return 'Adjustment';
      case 'transfer':
        return 'Transfer';
      default:
        return raw.trim().isEmpty ? 'Sale' : raw.trim();
    }
  }

  final String id;
  final String businessId;

  /// Canonical type (see [canonicalTypes]).
  final String type;

  final double amount;

  /// Links to FinancialCategory enum
  @enumerated
  final FinancialCategory category;

  final String? subCategory; // e.g., 'Rent', 'Electricity'

  @DateTimeConverter()
  final DateTime createdAt;

  /// Ledger date — the web contract's ordering field. REQUIRED on the wire
  /// as a Firestore Timestamp; falls back to [createdAt] for legacy docs.
  @DateTimeConverter()
  final DateTime date;

  final String description;

  /// Reference to the source document (Sale ID, Expense ID, StockIn ID)
  final String? referenceId;

  final String? paymentMethod;

  /// Optional audit fields the web sets on payment-confirmation ledgers.
  final String? performedBy;
  final String? performedByName;
  final String? workflowStage;

  const TransactionModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.createdAt,
    required this.date,
    required this.description,
    this.referenceId,
    this.paymentMethod,
    this.performedBy,
    this.performedByName,
    this.workflowStage,
  });

  factory TransactionModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['description'] ??= '';
    copy['referenceId'] ??= copy['relatedEntityId'];

    final amt = (copy['amount'] ?? 0.0) as num;
    copy['amount'] = amt.toDouble();

    copy['type'] = normalizeType(copy['type']?.toString());

    // Graceful category inference
    if (copy['category'] == null) {
      switch (copy['type'] as String) {
        case 'Expense':
          copy['category'] = 'opex';
          break;
        case 'Sale':
        case 'Customer Payment':
          copy['category'] = 'revenue';
          break;
        default:
          copy['category'] = 'revenue';
      }
    }

    // Flexible timestamp handling for `createdAt`
    dynamic rawDate = copy['timestamp'] ?? copy['date'] ?? copy['createdAt'];
    if (rawDate is Timestamp) {
      copy['createdAt'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['createdAt'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['createdAt'] = rawDate;
    } else {
      copy['createdAt'] = DateTime.now().toIso8601String();
    }

    // Ledger `date` — REQUIRED by web queries; fall back to `createdAt`
    // for legacy Flutter docs that never wrote it (they are invisible on web).
    dynamic rawLedgerDate = copy['date'];
    if (rawLedgerDate is Timestamp) {
      copy['date'] = rawLedgerDate.toDate().toIso8601String();
    } else if (rawLedgerDate is DateTime) {
      copy['date'] = rawLedgerDate.toIso8601String();
    } else if (rawLedgerDate is String && rawLedgerDate.isNotEmpty) {
      // keep as-is
    } else {
      copy['date'] = copy['createdAt'];
    }

    return _$TransactionModelFromJson(copy);
  }

  Map<String, dynamic> toJson() {
    final map = _$TransactionModelToJson(this);
    if (referenceId != null) {
      map['relatedEntityId'] = referenceId;
    }
    return map;
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
