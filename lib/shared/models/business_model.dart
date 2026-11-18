import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'business_model.g.dart';

// This converter will handle both Firestore Timestamps and ISO8601 strings.
class TimestampOrStringConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampOrStringConverter();

  @override
  DateTime? fromJson(final dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  dynamic toJson(final DateTime? date) => date?.toIso8601String();
}

@JsonSerializable(explicitToJson: true)
class BusinessModel {
  final String? id;
  final String? name;
  final String? description;
  @JsonKey(name: 'logoUrl')
  final String? logoUrl;
  final String? category;
  final String? industry;
  final String? size;
  final String? language;
  final List<String> goals;
  final String? address;
  final String? website;
  final String? phone;
  final String? email;
  @JsonKey(name: 'ownerId')
  final String? ownerId;
  @JsonKey(name: 'enabledModules')
  final dynamic enabledModules;
  final Map<String, dynamic>? settings;

  @TimestampOrStringConverter()
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @TimestampOrStringConverter()
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const BusinessModel({
    this.id,
    this.name,
    this.description,
    this.logoUrl,
    this.category,
    this.industry,
    this.size,
    this.language = 'en',
    this.goals = const [],
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

  String get currency =>
      settings?['currency']?.toString() ??
      settings?['currencyCode']?.toString() ??
      'USD';


  factory BusinessModel.fromJson(final Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);

  BusinessModel copyWith({
    final String? id,
    final String? name,
    final String? description,
    final String? logoUrl,
    final String? category,
    final String? industry,
    final String? size,
    final String? language,
    final List<String>? goals,
    final String? address,
    final String? phone,
    final String? website,
    final String? email,
    final String? ownerId,
    final dynamic enabledModules,
    final Map<String, dynamic>? settings,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    debugPrint(
      '[debug] Copying BusinessModel with new values: id=$id, ownerId=$ownerId, enabledModules=$enabledModules, settings=$settings, createdAt=$createdAt, updatedAt=$updatedAt',
    );
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      language: language ?? this.language,
      goals: goals ?? this.goals,
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
