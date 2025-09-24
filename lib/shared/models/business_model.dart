import 'package:json_annotation/json_annotation.dart';

part 'business_model.g.dart';

@JsonSerializable()
class BusinessModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String industry;
  final String address;
  final String phone;
  final String email;
  final String ownerId;
  final List<String> enabledModules;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.industry,
    required this.address,
    required this.phone,
    required this.email,
    required this.ownerId,
    required this.enabledModules,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) => _$BusinessModelFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);

  BusinessModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? industry,
    String? address,
    String? phone,
    String? email,
    String? ownerId,
    List<String>? enabledModules,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      industry: industry ?? this.industry,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ownerId: ownerId ?? this.ownerId,
      enabledModules: enabledModules ?? this.enabledModules,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 