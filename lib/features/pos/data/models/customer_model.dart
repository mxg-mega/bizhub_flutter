import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_model.g.dart';

@collection
@JsonSerializable()
class CustomerModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  
  /// The amount this customer owes the business
  final double outstandingBalance;
  
  /// List of Sale IDs associated with this customer
  final List<String> purchaseHistory;

  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.outstandingBalance = 0.0,
    this.purchaseHistory = const [],
    required this.createdAt,
  });

  factory CustomerModel.fromJson(final Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  CustomerModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? outstandingBalance,
    List<String>? purchaseHistory,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
