import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_payment_model.g.dart';

@collection
@JsonSerializable()
class CustomerPaymentModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String customerId;
  final double amount;
  final String paymentMethod; // cash, transfer, etc.
  final DateTime timestamp;
  final String? notes;

  const CustomerPaymentModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    this.notes,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerPaymentModelFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerPaymentModelToJson(this);

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
