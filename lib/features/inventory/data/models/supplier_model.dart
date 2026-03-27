import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'supplier_model.g.dart';

@collection
@JsonSerializable()
class SupplierModel {
  Id get isarId => _fastHash(id);

  @Index(unique: true)
  final String id;
  final String businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  
  /// Amount owed to this supplier
  final double balance;
  
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
    required this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) =>
      _$SupplierModelFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierModelToJson(this);

  SupplierModel copyWith({
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    double? balance,
  }) {
    return SupplierModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt,
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
