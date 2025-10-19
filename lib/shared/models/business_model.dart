import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'business_model.g.dart';

// This converter will handle both Firestore Timestamps and ISO8601 strings.
class TimestampOrStringConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampOrStringConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? date) => date?.toIso8601String();
}

@JsonSerializable(explicitToJson: true)
class BusinessModel {
  final String? id;
  final String? name;
  final String? description;
  final String? logoUrl;
  final String? category;
  final String? industry;
  final String? address;
  final String? website;
  final String? phone;
  final String? email;
  final String? ownerId;
  final Map<String, dynamic>? enabledModules;
  final Map<String, dynamic>? settings;

  @TimestampOrStringConverter()
  final DateTime? createdAt;

  @TimestampOrStringConverter()
  final DateTime? updatedAt;

  const BusinessModel({
    this.id,
    this.name,
    this.description,
    this.logoUrl,
    this.category,
    this.industry,
    this.address,
    this.website,
    this.phone,
    this.email,
    this.ownerId,
    this.enabledModules,
    this.settings,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);

  BusinessModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? category,
    String? industry,
    String? address,
    String? phone,
    String? website,
    String? email,
    String? ownerId,
    Map<String, dynamic>? enabledModules,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      industry: industry ?? this.industry,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      email: email ?? this.email,
      ownerId: ownerId ?? this.ownerId,
      enabledModules: enabledModules ?? this.enabledModules,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
