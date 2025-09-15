/// Custom exception for password validation failures
class PasswordMismatchException implements Exception {
  final String message;
  final String? code;
  
  const PasswordMismatchException(this.message, {this.code});
  
  @override
  String toString() => 'PasswordMismatchException: $message';
}

/// Custom exception for user authentication failures
class UserAuthenticationException implements Exception {
  final String message;
  final String? code;
  
  const UserAuthenticationException(this.message, {this.code});
  
  @override
  String toString() => 'UserAuthenticationException: $message';
}

/// Custom exception for user account issues
class UserAccountException implements Exception {
  final String message;
  final String? code;
  
  const UserAccountException(this.message, {this.code});
  
  @override
  String toString() => 'UserAccountException: $message';
}
