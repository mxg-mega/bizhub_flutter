import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_result.g.dart';

@JsonSerializable()
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? errorCode;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.errorCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResultToJson(this);

  factory AuthResult.success({required UserModel user, String? message}) {
    return AuthResult(success: true, user: user, message: message);
  }

  factory AuthResult.failure({required String message, String? errorCode}) {
    return AuthResult(success: false, message: message, errorCode: errorCode);
  }

  AuthResult copyWith({
    bool? success,
    String? message,
    UserModel? user,
    String? errorCode,
  }) {
    return AuthResult(
      success: success ?? this.success,
      message: message ?? this.message,
      user: user ?? this.user,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}
