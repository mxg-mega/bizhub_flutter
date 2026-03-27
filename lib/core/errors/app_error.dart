abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppError: $message';
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.code, super.originalError});
}

class AuthError extends AppError {
  const AuthError(super.message, {super.code, super.originalError});
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError(super.message, {this.fieldErrors = const {}, super.code, super.originalError});
}

class ServerError extends AppError {
  final int? statusCode;

  const ServerError(super.message, {this.statusCode, super.code, super.originalError});
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.code, super.originalError});
}
