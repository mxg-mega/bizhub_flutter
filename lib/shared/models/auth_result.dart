import 'package:json_annotation/json_annotation.dart';
import 'business_model.dart';
import 'user_model.dart';

part 'auth_result.g.dart';

@JsonSerializable()
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final BusinessModel? activeBusiness;
  final String? errorCode;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.activeBusiness,
    this.errorCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResultToJson(this);

  // TODO: set active business to be a required field
  factory AuthResult.success({required UserModel user, String? message, BusinessModel? activeBusiness,}) {
    return AuthResult(success: true, user: user, message: message, activeBusiness: activeBusiness);
  }

  factory AuthResult.failure({required String message, String? errorCode}) {
    return AuthResult(success: false, message: message, errorCode: errorCode);
  }

  AuthResult copyWith({
    bool? success,
    String? message,
    UserModel? user,
    BusinessModel? activeBusiness,
    String? errorCode,
  }) {
    return AuthResult(
      success: success ?? this.success,
      message: message ?? this.message,
      user: user ?? this.user,
      activeBusiness: activeBusiness ?? this.activeBusiness,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}
