import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/datetime_converter.dart';

part 'membership_model.g.dart';

@JsonSerializable()
class MembershipModel {
  final String businessId;
  final String userId;
  final String roleId;
  final String status; // active, invited, suspended
  final String? businessName;
  
  @DateTimeConverter()
  final DateTime? joinedAt;

  const MembershipModel({
    required this.businessId,
    required this.userId,
    required this.roleId,
    this.status = 'active',
    this.businessName,
    this.joinedAt,
  });

  factory MembershipModel.fromJson(final Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['businessId'] ??= copy['business_id'] ?? copy['id'] ?? '';
    copy['userId'] ??= copy['user_id'] ?? copy['uid'] ?? '';
    copy['roleId'] ??= copy['role_id'] ?? copy['role'] ?? 'Owner';
    copy['status'] ??= 'active';
    copy['businessName'] ??= copy['name'];
    return _$MembershipModelFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$MembershipModelToJson(this);

  MembershipModel copyWith({
    final String? businessId,
    final String? userId,
    final String? roleId,
    final String? status,
    final String? businessName,
    final DateTime? joinedAt,
  }) {
    return MembershipModel(
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      businessName: businessName ?? this.businessName,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
