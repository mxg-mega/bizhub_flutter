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
  // settings can be a complex object, so we use Map<String, dynamic>
  // but they should be defined in a way that they can be easily serialized and deserialized
  // also they are used to store user-specific configurations for each module, so they should be flexible and extensible to accommodate different types of settings for different modules
  final Map<String, dynamic> settings;
  // dependencies can be a list of module names that this module depends on, which can be used to ensure that the required modules are enabled before enabling this module, and to manage the relationships between different modules in the app
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

  factory ModuleModel.fromJson(final Map<String, dynamic> json) =>
      _$ModuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleModelToJson(this);

  ModuleModel copyWith({
    final String? id,
    final String? name,
    final String? description,
    final String? icon,
    final String? category,
    final bool? isEnabled,
    final bool? isPremium,
    final Map<String, dynamic>? settings,
    final List<String>? dependencies,
    final DateTime? createdAt,
    final DateTime? updatedAt,
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
