import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/datetime_converter.dart';

part 'module_model.g.dart';

@JsonSerializable()
class ModuleModel {
  final String id;
  final String name;
  final String path;
  final String icon;
  final bool isActive;
  final bool isInstalled;
  final bool enabledByDefault;
  final bool isPremium;
  final String category;
  final String? permissionId;
  
  final String? description;
  final Map<String, dynamic>? settings;
  final List<String>? dependencies;
  
  @DateTimeConverter()
  final DateTime? createdAt;
  
  @DateTimeConverter()
  final DateTime? updatedAt;

  const ModuleModel({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    this.isActive = true,
    this.isInstalled = false,
    this.enabledByDefault = false,
    this.isPremium = false,
    required this.category,
    this.permissionId,
    this.description,
    this.settings,
    this.dependencies,
    this.createdAt,
    this.updatedAt,
  });

  factory ModuleModel.fromJson(final Map<String, dynamic> json) =>
      _$ModuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleModelToJson(this);

  ModuleModel copyWith({
    final String? id,
    final String? name,
    final String? path,
    final String? icon,
    final bool? isActive,
    final bool? isInstalled,
    final bool? enabledByDefault,
    final bool? isPremium,
    final String? category,
    final String? permissionId,
    final String? description,
    final Map<String, dynamic>? settings,
    final List<String>? dependencies,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      isInstalled: isInstalled ?? this.isInstalled,
      enabledByDefault: enabledByDefault ?? this.enabledByDefault,
      isPremium: isPremium ?? this.isPremium,
      category: category ?? this.category,
      permissionId: permissionId ?? this.permissionId,
      description: description ?? this.description,
      settings: settings ?? this.settings,
      dependencies: dependencies ?? this.dependencies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
