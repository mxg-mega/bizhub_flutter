import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

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
  
  /// 'income' | 'expense' | 'transfer'
  final String type;
  
  final double amount;
  
  /// Links to FinancialCategory enum
  @enumerated
  final FinancialCategory category;
  
  final String? subCategory; // e.g., 'Rent', 'Electricity'
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

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
