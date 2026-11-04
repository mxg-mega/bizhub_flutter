import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/utils/datetime_converter.dart';
import 'permission_model.dart';

part 'user_model.g.dart';

@collection
@JsonSerializable()
class UserModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String? email;
  final String? name;
  @JsonKey(name: 'photoUrl')
  final String? photoUrl;
  
  /// List of business IDs the user belongs to.
  @JsonKey(name: 'businessIds')
  final List<String> businessIds;

  final String? role; // Temporary for backward compatibility in employee lists

  @JsonKey(name: 'isSuperAdmin')
  final bool isSuperAdmin;
  @JsonKey(name: 'onboardingCompleted')
  final bool onboardingCompleted;
  
  @DateTimeConverter()
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  
  @DateTimeConverter()
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
    this.businessIds = const [],
    this.role,
    this.isSuperAdmin = false,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] ??= copy['uid'] ?? 'unknown_id';
    copy['name'] ??= copy['displayName'] ?? copy['username'] ?? '';
    copy['businessIds'] ??= <String>[];
    copy['isSuperAdmin'] ??= false;
    copy['onboardingCompleted'] ??= (copy['businessIds'] as List).isNotEmpty;
    return _$UserModelFromJson(copy);
  }
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool hasPermission({
    required final RoleModel? role,
    required final String module,
    final String action = 'view',
  }) {
    if (isSuperAdmin) return true;
    if (role == null) return false;
    return PermissionManager.hasPermission(
      role: role,
      module: module,
      action: action,
    );
  }

  UserModel copyWith({
    final String? id,
    final String? email,
    final String? name,
    final String? photoUrl,
    final List<String>? businessIds,
    final String? role,
    final bool? isSuperAdmin,
    final bool? onboardingCompleted,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      businessIds: businessIds ?? this.businessIds,
      role: role ?? this.role,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
