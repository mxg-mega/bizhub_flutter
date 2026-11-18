import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/datetime_converter.dart';

part 'module_state_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ModuleStateModel {
  final bool enabled;

  @FirestoreDateTimeConverter()
  final DateTime? lastUpdated;

  @FirestoreDateTimeConverter()
  final DateTime? installedAt;

  final String installedBy;
  final String version;
  final String? previousVersion;
  final bool? isRollback;
  final Map<String, dynamic>? metadata;

  const ModuleStateModel({
    required this.enabled,
    this.lastUpdated,
    this.installedAt,
    this.installedBy = 'system',
    this.version = '1.0.0',
    this.previousVersion,
    this.isRollback,
    this.metadata,
  });

  factory ModuleStateModel.fromJson(final Map<String, dynamic> json) =>
      _$ModuleStateModelFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleStateModelToJson(this);

  /// Converts this model into a Firestore map using FieldValue.serverTimestamp()
  /// for timestamp fields if desired, or serializes with Timestamps.
  Map<String, dynamic> toFirestoreMap({final bool useServerTimestamp = true}) {
    final map = toJson();
    debugPrint('[debug] Converting ModuleStateModel to Firestore map: $map');
    if (useServerTimestamp) {
      map['lastUpdated'] = FieldValue.serverTimestamp();
      if (installedAt == null) {
        map['installedAt'] = FieldValue.serverTimestamp();
      }
    }
    return map;
  }

  ModuleStateModel copyWith({
    final bool? enabled,
    final DateTime? lastUpdated,
    final DateTime? installedAt,
    final String? installedBy,
    final String? version,
    final String? previousVersion,
    final bool? isRollback,
    final Map<String, dynamic>? metadata,
  }) {
    return ModuleStateModel(
      enabled: enabled ?? this.enabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      installedAt: installedAt ?? this.installedAt,
      installedBy: installedBy ?? this.installedBy,
      version: version ?? this.version,
      previousVersion: previousVersion ?? this.previousVersion,
      isRollback: isRollback ?? this.isRollback,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper to evaluate whether a module entry is enabled from any supported dynamic format:
  /// - Boolean (legacy Flutter format: `true` / `false` or `'true'`)
  /// - Map / Object (NextJS format: `{ "enabled": true, ... }`)
  static bool isEnabled(final dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is Map) {
      final dynamic enabledVal = value['enabled'];
      if (enabledVal is bool) return enabledVal;
      if (enabledVal is String) return enabledVal.toLowerCase() == 'true';
    }
    return false;
  }

  /// Parses a dynamic value (bool or Map) into a ModuleStateModel.
  static ModuleStateModel fromDynamic(final dynamic value) {
    if (value is ModuleStateModel) return value;
    if (value is bool) {
      return ModuleStateModel(
        enabled: value,
        lastUpdated: DateTime.now(),
        installedAt: DateTime.now(),
      );
    }
    if (value is Map) {
      return ModuleStateModel.fromJson(Map<String, dynamic>.from(value));
    }
    return const ModuleStateModel(enabled: false);
  }
}
