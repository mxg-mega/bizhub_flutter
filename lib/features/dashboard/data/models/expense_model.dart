import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'expense_model.g.dart';

@collection
@JsonSerializable()
class ExpenseModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String category; // 'Rent', 'Salaries', 'Utilities', 'Inventory', 'Other'
  final double amount;
  
  @DateTimeConverter()
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

  factory ExpenseModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['category'] ??= 'Other';
    copy['amount'] = ((copy['amount'] ?? 0.0) as num).toDouble();

    dynamic rawDate = copy['date'] ?? copy['createdAt'];
    if (rawDate is Timestamp) {
      copy['date'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['date'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['date'] = rawDate;
    } else {
      copy['date'] = DateTime.now().toIso8601String();
    }

    return _$ExpenseModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

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
