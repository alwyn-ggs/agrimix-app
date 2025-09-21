import 'package:logger/logger.dart';

/// Centralized logger configuration for the AgriMix app
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      // ignore: deprecated_member_use
      printTime: true,
    ),
  );

  /// Log debug messages
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log info messages
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning messages
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal messages
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
