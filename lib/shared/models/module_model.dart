import 'package:json_annotation/json_annotation.dart';

part 'module_model.g.dart';

@JsonSerializable()
class ModuleModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool isEnabled;
  final bool isPremium;
  final Map<String, dynamic> settings;
  final List<String> dependencies;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.isEnabled,
    required this.isPremium,
    required this.settings,
    required this.dependencies,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) =>
      _$ModuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleModelToJson(this);

  ModuleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? category,
    bool? isEnabled,
    bool? isPremium,
    Map<String, dynamic>? settings,
    List<String>? dependencies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      isPremium: isPremium ?? this.isPremium,
      settings: settings ?? this.settings,
      dependencies: dependencies ?? this.dependencies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
