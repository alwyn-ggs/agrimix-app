import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'feedback_service.dart';

/// Centralized error handling service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Handle and categorize errors
  static AppErrorType categorizeError(dynamic error) {
    if (error == null) return AppErrorType.unknown;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('internet')) {
      return AppErrorType.network;
    }

    // Authentication errors
    if (errorString.contains('auth') ||
        errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('invalid-credential') ||
        errorString.contains('user-not-found') ||
        errorString.contains('wrong-password') ||
        errorString.contains('email-already-in-use') ||
        errorString.contains('email address is already in use') ||
        errorString.contains('sign_in_failed') ||
        errorString.contains('apiexception') ||
        errorString.contains('developer_error') ||
        errorString.contains('10:')) {
      return AppErrorType.authentication;
    }

    // Firebase/Firestore errors
    if (errorString.contains('firebase') ||
        errorString.contains('firestore') ||
        errorString.contains('cloud_firestore') ||
        errorString.contains('permission-denied') ||
        errorString.contains('not-found') ||
        errorString.contains('already-exists')) {
      return AppErrorType.firebase;
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required') ||
        errorString.contains('format')) {
      return AppErrorType.validation;
    }

    // Storage errors
    if (errorString.contains('storage') ||
        errorString.contains('upload') ||
        errorString.contains('download') ||
        errorString.contains('file')) {
      return AppErrorType.storage;
    }

    // Server errors
    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return AppErrorType.server;
    }

    return AppErrorType.unknown;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error, AppErrorType? type) {
    if (error == null) return 'An unexpected error occurred';

    final errorType = type ?? categorizeError(error);
    final errorString = error.toString();

    switch (errorType) {
      case AppErrorType.network:
        return 'Please check your internet connection and try again.';
      
      case AppErrorType.authentication:
        // Google Sign-In specific errors
        if (errorString.contains('sign_in_failed') ||
            errorString.contains('apiexception') ||
            errorString.contains('developer_error') ||
            errorString.contains('10:')) {
          return 'Google Sign-In configuration error. Please contact support or check Firebase setup.';
        }
        if (errorString.contains('invalid-credential') ||
            errorString.contains('wrong-password')) {
          return 'Invalid email or password. Please try again.';
        }
        if (errorString.contains('user-not-found')) {
          return 'No account found with this email address.';
        }
        if (errorString.contains('email-already-in-use') ||
            errorString.contains('email address is already in use')) {
          return 'Account already exists and is under review. Please wait for administrator approval.';
        }
        if (errorString.contains('permission') ||
            errorString.contains('unauthorized')) {
          return 'You do not have permission to perform this action.';
        }
        return 'Authentication failed. Please sign in again.';
      
      case AppErrorType.firebase:
        if (errorString.contains('permission-denied')) {
          return 'You do not have permission to access this data.';
        }
        if (errorString.contains('not-found')) {
          return 'The requested data was not found.';
        }
        if (errorString.contains('already-exists')) {
          return 'This item already exists.';
        }
        return 'A database error occurred. Please try again.';
      
      case AppErrorType.validation:
        if (errorString.contains('email')) {
          return 'Please enter a valid email address.';
        }
        if (errorString.contains('password')) {
          return 'Password must be at least 6 characters long.';
        }
        if (errorString.contains('required')) {
          return 'Please fill in all required fields.';
        }
        return 'Please check your input and try again.';
      
      case AppErrorType.storage:
        if (errorString.contains('upload')) {
          return 'Failed to upload file. Please try again.';
        }
        if (errorString.contains('download')) {
          return 'Failed to download file. Please try again.';
        }
        return 'A file operation failed. Please try again.';
      
      case AppErrorType.server:
        return 'Server is temporarily unavailable. Please try again later.';
      
      case AppErrorType.unknown:
      // In debug mode, show the actual error
        if (kDebugMode) {
          return errorString;
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle error with logging and user notification
  static void handleError(
    dynamic error, {
    String? context,
    bool showToUser = true,
    VoidCallback? onRetry,
  }) {
    final errorType = categorizeError(error);
    final userMessage = getUserFriendlyMessage(error, errorType);

    // Log the error
    AppLogger.error(
      'Error${context != null ? ' in $context' : ''}: $error',
      error,
    );

    // In debug mode, also print to console
    if (kDebugMode) {
      print('Error${context != null ? ' in $context' : ''}: $error');
      print('Error Type: $errorType');
      print('User Message: $userMessage');
    }

    // Surface to user via centralized feedback with light dedupe
    if (showToUser) {
      // Choose color by error type (optional; keep subtle defaults)
      Color? bg;
      switch (errorType) {
        case AppErrorType.network:
        case AppErrorType.server:
        case AppErrorType.firebase:
          bg = const Color(0xFFB00020); // red tone
          break;
        case AppErrorType.validation:
          bg = const Color(0xFFEF6C00); // orange tone
          break;
        case AppErrorType.authentication:
        case AppErrorType.storage:
        case AppErrorType.unknown:
          bg = const Color(0xFFB00020);
          break;
      }
      FeedbackService().showSnack(userMessage, backgroundColor: bg);
    }
  }

  /// Handle Firebase specific errors
  static void handleFirebaseError(dynamic error, {String? context}) {
    handleError(
      error,
      context: context ?? 'Firebase operation',
      showToUser: true,
    );
  }

  /// Handle network specific errors
  static void handleNetworkError(dynamic error, {String? context}) {
    handleError(
      error,
      context: context ?? 'Network operation',
      showToUser: true,
    );
  }

  /// Handle authentication specific errors
  static void handleAuthError(dynamic error, {String? context}) {
    handleError(
      error,
      context: context ?? 'Authentication',
      showToUser: true,
    );
  }
}

/// Error types for categorization
enum AppErrorType {
  network,
  authentication,
  firebase,
  validation,
  storage,
  server,
  unknown,
}

/// Error handling mixin for providers
mixin ErrorHandlerMixin {
  String? _error;
  bool _hasError = false;

  String? get error => _error;
  bool get hasError => _hasError;

  void setError(dynamic error, {String? context}) {
    _error = ErrorHandlerService.getUserFriendlyMessage(error, null);
    _hasError = true;
    ErrorHandlerService.handleError(error, context: context);
  }

  /// Set a non-blocking error message that can be rendered inline by the UI
  /// without triggering global error pages.
  void setErrorMessage(String message) {
    _error = message;
    _hasError = false; // keep it inline; do not elevate to global error
  }

  void clearError() {
    _error = null;
    _hasError = false;
  }

  void handleError(dynamic error, {String? context}) {
    setError(error, context: context);
  }
}
