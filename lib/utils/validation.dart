import 'package:cloud_firestore/cloud_firestore.dart';

/// Validation result class to hold validation errors and warnings
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  ValidationResult copyWith({
    bool? isValid,
    List<String>? errors,
    List<String>? warnings,
  }) {
    return ValidationResult(
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
    );
  }

  /// Combine multiple validation results
  static ValidationResult combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    bool isValid = true;

    for (final result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
      if (!result.isValid) {
        isValid = false;
      }
    }

    return ValidationResult(
      isValid: isValid,
      errors: allErrors,
      warnings: allWarnings,
    );
  }
}

/// Base validation utilities
class ValidationUtils {
  /// Validate required string field
  static ValidationResult validateRequiredString(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errors: ['$fieldName is required'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Validate string length
  static ValidationResult validateStringLength(String value, String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    final length = value.length;
    final errors = <String>[];

    if (minLength != null && length < minLength) {
      errors.add('$fieldName must be at least $minLength characters long');
    }
    if (maxLength != null && length > maxLength) {
      errors.add('$fieldName must be no more than $maxLength characters long');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate email format
  static ValidationResult validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return const ValidationResult(
        isValid: false,
        errors: ['Invalid email format'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Validate positive number
  static ValidationResult validatePositiveNumber(num? value, String fieldName) {
    if (value == null) {
      return ValidationResult(
        isValid: false,
        errors: ['$fieldName is required'],
      );
    }
    if (value <= 0) {
      return ValidationResult(
        isValid: false,
        errors: ['$fieldName must be greater than 0'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Validate number range
  static ValidationResult validateNumberRange(num value, String fieldName, {
    num? min,
    num? max,
  }) {
    final errors = <String>[];

    if (min != null && value < min) {
      errors.add('$fieldName must be at least $min');
    }
    if (max != null && value > max) {
      errors.add('$fieldName must be no more than $max');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate date range
  static ValidationResult validateDateRange(DateTime date, String fieldName, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    final errors = <String>[];

    if (minDate != null && date.isBefore(minDate)) {
      errors.add('$fieldName cannot be before ${minDate.toIso8601String().split('T')[0]}');
    }
    if (maxDate != null && date.isAfter(maxDate)) {
      errors.add('$fieldName cannot be after ${maxDate.toIso8601String().split('T')[0]}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate non-empty list
  static ValidationResult validateNonEmptyList<T>(List<T> list, String fieldName) {
    if (list.isEmpty) {
      return ValidationResult(
        isValid: false,
        errors: ['$fieldName must contain at least one item'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Validate list length
  static ValidationResult validateListLength<T>(List<T> list, String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    final length = list.length;
    final errors = <String>[];

    if (minLength != null && length < minLength) {
      errors.add('$fieldName must contain at least $minLength items');
    }
    if (maxLength != null && length > maxLength) {
      errors.add('$fieldName must contain no more than $maxLength items');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate URL format
  static ValidationResult validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return const ValidationResult(
          isValid: false,
          errors: ['Invalid URL format'],
        );
      }
      return const ValidationResult(isValid: true);
    } catch (e) {
      return const ValidationResult(
        isValid: false,
        errors: ['Invalid URL format'],
      );
    }
  }

  /// Validate UID format (Firebase UID)
  static ValidationResult validateUid(String uid) {
    if (uid.length < 20 || uid.length > 128) {
      return const ValidationResult(
        isValid: false,
        errors: ['Invalid UID format'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Validate enum value
  static ValidationResult validateEnum<T>(T value, List<T> validValues, String fieldName) {
    if (!validValues.contains(value)) {
      return ValidationResult(
        isValid: false,
        errors: ['Invalid $fieldName value'],
      );
    }
    return const ValidationResult(isValid: true);
  }

  /// Safe parse timestamp
  static DateTime? safeParseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Safe parse boolean
  static bool safeParseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value != 0;
    }
    return false;
  }

  /// Safe parse number
  static num? safeParseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// Safe parse string list
  static List<String> safeParseStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}

/// Model version information
class ModelVersion {
  final int major;
  final int minor;
  final int patch;

  const ModelVersion(this.major, this.minor, this.patch);

  factory ModelVersion.fromString(String version) {
    final parts = version.split('.');
    return ModelVersion(
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
      int.tryParse(parts[2]) ?? 0,
    );
  }

  @override
  String toString() => '$major.$minor.$patch';

  bool isCompatibleWith(ModelVersion other) {
    return major == other.major;
  }

  bool isNewerThan(ModelVersion other) {
    if (major > other.major) return true;
    if (major < other.major) return false;
    if (minor > other.minor) return true;
    if (minor < other.minor) return false;
    return patch > other.patch;
  }
}

/// Base class for all model validators
abstract class ModelValidator<T> {
  /// Validate the model instance
  ValidationResult validate(T model);

  /// Validate data before creating model instance
  ValidationResult validateData(Map<String, dynamic> data);

  /// Get model version
  ModelVersion get version;

  /// Check if data version is compatible
  bool isDataCompatible(Map<String, dynamic> data) {
    final dataVersion = _extractVersion(data);
    return version.isCompatibleWith(dataVersion);
  }

  /// Extract version from data
  ModelVersion _extractVersion(Map<String, dynamic> data) {
    final versionString = data['_version'] as String? ?? '1.0.0';
    return ModelVersion.fromString(versionString);
  }
}
