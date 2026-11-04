import 'package:json_annotation/json_annotation.dart';

part 'permission_model.g.dart';

@JsonSerializable()
class PermissionActions {
  final bool view;
  final bool create;
  final bool edit;
  final bool delete;
  final bool approve;
  final bool export;

  const PermissionActions({
    this.view = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
    this.approve = false,
    this.export = false,
  });

  factory PermissionActions.fromJson(final Map<String, dynamic> json) =>
      _$PermissionActionsFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionActionsToJson(this);

  PermissionActions copyWith({
    final bool? view,
    final bool? create,
    final bool? edit,
    final bool? delete,
    final bool? approve,
    final bool? export,
  }) {
    return PermissionActions(
      view: view ?? this.view,
      create: create ?? this.create,
      edit: edit ?? this.edit,
      delete: delete ?? this.delete,
      approve: approve ?? this.approve,
      export: export ?? this.export,
    );
  }
}

@JsonSerializable()
class RoleModel {
  final String id;
  final String name;
  final bool isSystem;
  final List<String> permissions; // Legacy (module IDs)
  final Map<String, PermissionActions>? permissionsMap; // Enhanced

  const RoleModel({
    required this.id,
    required this.name,
    this.isSystem = false,
    this.permissions = const [],
    this.permissionsMap,
  });

  factory RoleModel.fromJson(final Map<String, dynamic> json) =>
      _$RoleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoleModelToJson(this);

  RoleModel copyWith({
    final String? id,
    final String? name,
    final bool? isSystem,
    final List<String>? permissions,
    final Map<String, PermissionActions>? permissionsMap,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isSystem: isSystem ?? this.isSystem,
      permissions: permissions ?? this.permissions,
      permissionsMap: permissionsMap ?? this.permissionsMap,
    );
  }
}
