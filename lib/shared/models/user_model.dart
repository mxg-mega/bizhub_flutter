import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? role;
  final List<Map<String, dynamic>>? businessIds;
  final List<Map<String, dynamic>>? enabledModules;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  set name(final String? value) {
    name = value;
  }

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.businessIds,
    required this.enabledModules,
    required this.createdAt,
    required this.updatedAt,
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
}
