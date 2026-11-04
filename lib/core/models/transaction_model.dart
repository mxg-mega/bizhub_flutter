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

  final String id;
  final String businessId;
  
  /// 'income' | 'expense' | 'transfer' | 'sale'
  final String type;
  
  final double amount;
  
  /// Links to FinancialCategory enum
  @enumerated
  final FinancialCategory category;
  
  final String? subCategory; // e.g., 'Rent', 'Electricity'
  
  @DateTimeConverter()
  final DateTime timestamp;
  
  final String description;
  
  /// Reference to the source document (Sale ID, Expense ID, StockIn ID)
  final String? referenceId;
  
  final String? paymentMethod;

  const TransactionModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.timestamp,
    required this.description,
    this.referenceId,
    this.paymentMethod,
  });

  factory TransactionModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['description'] ??= '';
    copy['referenceId'] ??= copy['relatedEntityId'];

    final amt = (copy['amount'] ?? 0.0) as num;
    copy['amount'] = amt.toDouble();

    final rawType = (copy['type'] ?? 'income').toString().toLowerCase();
    copy['type'] = rawType;

    // Graceful category inference
    if (copy['category'] == null) {
      if (rawType.contains('expense')) {
        copy['category'] = 'opex';
      } else {
        copy['category'] = 'revenue';
      }
    }

    // Flexible timestamp / date handling
    dynamic rawDate = copy['timestamp'] ?? copy['date'] ?? copy['createdAt'];
    if (rawDate is Timestamp) {
      copy['timestamp'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['timestamp'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['timestamp'] = rawDate;
    } else {
      copy['timestamp'] = DateTime.now().toIso8601String();
    }

    return _$TransactionModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

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
