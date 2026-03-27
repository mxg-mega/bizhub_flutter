import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/auth/role_permissions.dart';

part 'user_model.g.dart';

@collection
@JsonSerializable()
class UserModel {
  Id get isarId => _fastHash(uid);

  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? role;
  
  /// List of business memberships
  @ignore
  final List<Map<String, dynamic>>? businessIds;
  
  @ignore
  final List<Map<String, dynamic>>? enabledModules;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    this.businessIds,
    this.enabledModules,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    List<Map<String, dynamic>>? businessIds,
    List<Map<String, dynamic>>? enabledModules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      businessIds: businessIds ?? this.businessIds,
      enabledModules: enabledModules ?? this.enabledModules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Permission Helpers
  @ignore
  AppRole get appRole => AppRole.fromString(role);

  bool hasPermission(final AppPermission permission) => appRole.hasPermission(permission);

  int _fastHash(String string) {
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
