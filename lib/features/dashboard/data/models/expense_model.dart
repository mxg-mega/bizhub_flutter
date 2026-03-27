import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

@collection
@JsonSerializable()
class ExpenseModel {
  Id get isarId => _fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  @Index()
  final String businessId;
  
  final String category; // 'Rent', 'Salaries', 'Utilities', 'Inventory', 'Other'
  final double amount;
  
  @Index()
  final DateTime date;
  
  final String? description;
  final String? proofUrl; // Link to receipt image
  final String? userId; // Who recorded it

  const ExpenseModel({
    required this.id,
    required this.businessId,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.proofUrl,
    this.userId,
  });

  factory ExpenseModel.fromJson(final Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

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
