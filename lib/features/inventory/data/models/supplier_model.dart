import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'supplier_model.g.dart';

@collection
@JsonSerializable()
class SupplierModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  
  /// Amount owed to this supplier
  final double balance;
  
  @DateTimeConverter()
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

  factory SupplierModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= 'unknown_id';
    copy['businessId'] ??= copy['business_id'] ?? '';
    copy['name'] ??= 'Unnamed Supplier';
    copy['balance'] = ((copy['balance'] ?? 0.0) as num).toDouble();

    dynamic rawDate = copy['createdAt'] ?? copy['date'];
    if (rawDate is Timestamp) {
      copy['createdAt'] = rawDate.toDate().toIso8601String();
    } else if (rawDate is DateTime) {
      copy['createdAt'] = rawDate.toIso8601String();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      copy['createdAt'] = rawDate;
    } else {
      copy['createdAt'] = DateTime.now().toIso8601String();
    }

    return _$SupplierModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$SupplierModelToJson(this);

  SupplierModel copyWith({
    final String? name,
    final String? contactName,
    final String? phone,
    final String? email,
    final String? address,
    final double? balance,
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
