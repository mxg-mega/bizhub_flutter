abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppError: $message';
}

class NetworkError extends AppError {
  const NetworkError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class AuthError extends AppError {
  const AuthError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError(String message, {this.fieldErrors = const {}, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ServerError extends AppError {
  final int? statusCode;

  const ServerError(String message, {this.statusCode, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class UnknownError extends AppError {
  const UnknownError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
