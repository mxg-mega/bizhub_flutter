import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'customer_model.g.dart';

@collection
@JsonSerializable(fieldRename: FieldRename.none)
class CustomerModel {
  static const String walkInId = 'walk-in';
  static const String walkInName = 'Walk-in Customer';

  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  
  /// The amount this customer owes the business
  @JsonKey(defaultValue: 0.0)
  final double outstandingBalance;
  
  /// List of Sale IDs associated with this customer
  @JsonKey(defaultValue: [])
  final List<String> purchaseHistory;

  @DateTimeConverter()
  final DateTime? createdAt;

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

  factory CustomerModel.fromJson(final Map<String, dynamic> json) {
    // Inject defaults for required fields if missing
    json['id'] ??= 'unknown_id';
    json['businessId'] ??= 'unknown_business';
    json['name'] ??= 'Unnamed Customer';
    
    // Ensure numeric fields are doubles
    if (json['outstandingBalance'] != null) {
      json['outstandingBalance'] = (json['outstandingBalance'] as num).toDouble();
    }
    
    return _$CustomerModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  CustomerModel copyWith({
    final String? id,
    final String? businessId,
    final String? name,
    final String? phone,
    final String? email,
    final String? address,
    final double? outstandingBalance,
    final List<String>? purchaseHistory,
    final DateTime? createdAt,
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
