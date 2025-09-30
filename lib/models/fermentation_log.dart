import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/validation.dart';

enum FermentationStatus { active, done, cancelled }
enum FermentationMethod { ffj, fpj }

class FermentationStage {
  final int day;
  final String label;
  final String action;

  const FermentationStage({
    required this.day,
    required this.label,
    required this.action,
  });

  factory FermentationStage.fromMap(Map<String, dynamic> map) => FermentationStage(
        day: (map['day'] ?? 0) as int,
        label: map['label'] ?? '',
        action: map['action'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'label': label,
        'action': action,
      };

  /// Validate fermentation stage
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate day
    results.add(ValidationUtils.validateNumberRange(day, 'Day', min: 0, max: 365));
    
    // Validate label
    results.add(ValidationUtils.validateRequiredString(label, 'Label'));
    results.add(ValidationUtils.validateStringLength(label, 'Label', minLength: 1, maxLength: 100));
    
    // Validate action
    results.add(ValidationUtils.validateRequiredString(action, 'Action'));
    results.add(ValidationUtils.validateStringLength(action, 'Action', minLength: 1, maxLength: 500));

    return ValidationResult.combine(results);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FermentationStage &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          label == other.label &&
          action == other.action;

  @override
  int get hashCode => Object.hash(day, label, action);
}

class FermentationIngredient {
  final String name;
  final double amount;
  final String unit;

  const FermentationIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory FermentationIngredient.fromMap(Map<String, dynamic> map) => FermentationIngredient(
        name: map['name'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'unit': unit,
      };

  /// Validate fermentation ingredient
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate name
    results.add(ValidationUtils.validateRequiredString(name, 'Ingredient name'));
    results.add(ValidationUtils.validateStringLength(name, 'Ingredient name', minLength: 1, maxLength: 100));
    
    // Validate amount
    results.add(ValidationUtils.validatePositiveNumber(amount, 'Amount'));
    results.add(ValidationUtils.validateNumberRange(amount, 'Amount', min: 0.001, max: 10000));
    
    // Validate unit
    results.add(ValidationUtils.validateRequiredString(unit, 'Unit'));
    results.add(ValidationUtils.validateStringLength(unit, 'Unit', minLength: 1, maxLength: 20));

    return ValidationResult.combine(results);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FermentationIngredient &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          amount == other.amount &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(name, amount, unit);
}

class FermentationLog {
  final String id;
  final String ownerUid;
  final String? recipeId;
  final String title;
  final FermentationMethod method;
  final List<FermentationIngredient> ingredients;
  final DateTime startAt;
  final List<FermentationStage> stages;
  final int currentStage;
  final FermentationStatus status;
  final String? notes;
  final List<String> photos;
  final bool alertsEnabled;
  final DateTime createdAt;

  const FermentationLog({
    required this.id,
    required this.ownerUid,
    this.recipeId,
    required this.title,
    required this.method,
    required this.ingredients,
    required this.startAt,
    required this.stages,
    required this.currentStage,
    required this.status,
    this.notes,
    required this.photos,
    required this.alertsEnabled,
    required this.createdAt,
  });

  static const String collectionPath = 'fermentation_logs';
  static String docPath(String id) => 'fermentation_logs/$id';

  factory FermentationLog.fromMap(String id, Map<String, dynamic> map) => FermentationLog(
        id: id,
        ownerUid: map['ownerUid'] ?? '',
        recipeId: map['recipeId'],
        title: map['title'] ?? '',
        method: (map['method'] == 'fpj') ? FermentationMethod.fpj : FermentationMethod.ffj,
        ingredients: _parseIngredients(map['ingredients']),
        startAt: map['startAt'] is Timestamp
            ? (map['startAt'] as Timestamp).toDate()
            : DateTime.now(),
        stages: _parseStages(map['stages']),
        currentStage: (map['currentStage'] ?? 0) as int,
        status: map['status'] == 'done'
            ? FermentationStatus.done
            : map['status'] == 'cancelled'
                ? FermentationStatus.cancelled
                : FermentationStatus.active,
        notes: map['notes'],
        photos: _parsePhotos(map['photos']),
        alertsEnabled: (map['alertsEnabled'] ?? true) as bool,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory FermentationLog.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return FermentationLog.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'recipeId': recipeId,
        'title': title,
        'method': method == FermentationMethod.fpj ? 'fpj' : 'ffj',
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'startAt': Timestamp.fromDate(startAt),
        'stages': stages.map((e) => e.toMap()).toList(),
        'currentStage': currentStage,
        'status': status == FermentationStatus.done
            ? 'done'
            : status == FermentationStatus.cancelled
                ? 'cancelled'
                : 'active',
        'notes': notes,
        'photos': photos,
        'alertsEnabled': alertsEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FermentationLog copyWith({
    String? ownerUid,
    String? recipeId,
    String? title,
    FermentationMethod? method,
    List<FermentationIngredient>? ingredients,
    DateTime? startAt,
    List<FermentationStage>? stages,
    int? currentStage,
    FermentationStatus? status,
    String? notes,
    List<String>? photos,
    bool? alertsEnabled,
    DateTime? createdAt,
  }) => FermentationLog(
        id: id,
        ownerUid: ownerUid ?? this.ownerUid,
        recipeId: recipeId ?? this.recipeId,
        title: title ?? this.title,
        method: method ?? this.method,
        ingredients: ingredients ?? this.ingredients,
        startAt: startAt ?? this.startAt,
        stages: stages ?? this.stages,
        currentStage: currentStage ?? this.currentStage,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        photos: photos ?? this.photos,
        alertsEnabled: alertsEnabled ?? this.alertsEnabled,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FermentationLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerUid == other.ownerUid &&
          recipeId == other.recipeId &&
          title == other.title &&
          method == other.method &&
          _listEquals(ingredients, other.ingredients) &&
          startAt == other.startAt &&
          _listEquals(stages, other.stages) &&
          currentStage == other.currentStage &&
          status == other.status &&
          notes == other.notes &&
          _listEquals(photos, other.photos) &&
          alertsEnabled == other.alertsEnabled &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        ownerUid,
        recipeId,
        title,
        method,
        Object.hashAll(ingredients.map((e) => Object.hash(e.name, e.amount, e.unit))),
        startAt,
        Object.hashAll(stages.map((e) => Object.hash(e.day, e.label, e.action))),
        currentStage,
        status,
        notes,
        Object.hashAll(photos),
        alertsEnabled,
        createdAt,
      );

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<FermentationIngredient> _parseIngredients(dynamic ingredientsData) {
    try {
      if (ingredientsData is List) {
        return ingredientsData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return FermentationIngredient.fromMap(e);
                } else if (e is Map) {
                  return FermentationIngredient.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing ingredient: $e', e);
                return null;
              }
            })
            .where((ingredient) => ingredient != null)
            .cast<FermentationIngredient>()
            .toList();
      }
      return const <FermentationIngredient>[];
    } catch (e) {
      AppLogger.error('Error parsing ingredients list: $e', e);
      return const <FermentationIngredient>[];
    }
  }

  static List<FermentationStage> _parseStages(dynamic stagesData) {
    try {
      if (stagesData is List) {
        return stagesData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return FermentationStage.fromMap(e);
                } else if (e is Map) {
                  return FermentationStage.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing stage: $e', e);
                return null;
              }
            })
            .where((stage) => stage != null)
            .cast<FermentationStage>()
            .toList();
      }
      return const <FermentationStage>[];
    } catch (e) {
      AppLogger.error('Error parsing stages list: $e', e);
      return const <FermentationStage>[];
    }
  }

  static List<String> _parsePhotos(dynamic photosData) {
    try {
      if (photosData is List) {
        return photosData
            .map((e) => e.toString())
            .where((photo) => photo.isNotEmpty)
            .toList();
      }
      return const <String>[];
    } catch (e) {
      AppLogger.error('Error parsing photos list: $e', e);
      return const <String>[];
    }
  }

  /// Validate fermentation log
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate owner UID
    results.add(ValidationUtils.validateRequiredString(ownerUid, 'Owner UID'));
    results.add(ValidationUtils.validateUid(ownerUid));

    // Validate title
    results.add(ValidationUtils.validateRequiredString(title, 'Title'));
    results.add(ValidationUtils.validateStringLength(title, 'Title', minLength: 1, maxLength: 200));

    // Validate method
    results.add(ValidationUtils.validateEnum(method, FermentationMethod.values, 'Method'));

    // Validate ingredients
    results.add(ValidationUtils.validateNonEmptyList(ingredients, 'Ingredients'));
    results.add(ValidationUtils.validateListLength(ingredients, 'Ingredients', maxLength: 50));
    
    // Validate each ingredient
    for (int i = 0; i < ingredients.length; i++) {
      final ingredientResult = ingredients[i].validate();
      if (!ingredientResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: ingredientResult.errors.map((e) => 'Ingredient ${i + 1}: $e').toList(),
        ));
      }
    }

    // Validate start date
    final now = DateTime.now();
    final oneYearFromNow = now.add(const Duration(days: 365));
    results.add(ValidationUtils.validateDateRange(startAt, 'Start date', 
      maxDate: oneYearFromNow));

    // Validate stages
    results.add(ValidationUtils.validateNonEmptyList(stages, 'Stages'));
    results.add(ValidationUtils.validateListLength(stages, 'Stages', maxLength: 100));
    
    // Validate each stage
    for (int i = 0; i < stages.length; i++) {
      final stageResult = stages[i].validate();
      if (!stageResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: stageResult.errors.map((e) => 'Stage ${i + 1}: $e').toList(),
        ));
      }
    }

    // Validate current stage
    results.add(ValidationUtils.validateNumberRange(currentStage, 'Current stage', 
      min: 0, max: stages.length - 1));

    // Validate status
    results.add(ValidationUtils.validateEnum(status, FermentationStatus.values, 'Status'));

    // Validate notes (optional)
    if (notes != null && notes!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(notes!, 'Notes', maxLength: 2000));
    }

    // Validate photos
    results.add(ValidationUtils.validateListLength(photos, 'Photos', maxLength: 20));
    
    // Validate each photo URL
    for (int i = 0; i < photos.length; i++) {
      final photoResult = ValidationUtils.validateUrl(photos[i]);
      if (!photoResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Photo ${i + 1}: Invalid URL format'],
        ));
      }
    }

    // Validate created date
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created date', 
      maxDate: now));

    // Business logic validations
    if (status == FermentationStatus.done && currentStage < stages.length - 1) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Completed fermentation must be at the final stage'],
      ));
    }

    if (startAt.isAfter(now)) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Start date cannot be in the future'],
      ));
    }

    return ValidationResult.combine(results);
  }

  /// Check if fermentation log is valid (convenience method)
  bool get isValid => validate().isValid;

  /// Get validation errors (convenience method)
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings (convenience method)
  List<String> get validationWarnings => validate().warnings;

  /// Data migration support for version differences
  static FermentationLog fromMapWithMigration(String id, Map<String, dynamic> map) {
    final version = _extractVersion(map);
    const currentVersion = ModelVersion(1, 0, 0);
    
    if (!currentVersion.isCompatibleWith(version)) {
      AppLogger.warning('Incompatible data version: $version, expected: $currentVersion');
    }

    // Apply migrations based on version
    final migratedData = _applyMigrations(map, version, currentVersion);
    
    return FermentationLog.fromMap(id, migratedData);
  }

  /// Extract version from data
  static ModelVersion _extractVersion(Map<String, dynamic> data) {
    final versionString = data['_version'] as String? ?? '1.0.0';
    return ModelVersion.fromString(versionString);
  }

  /// Apply data migrations
  static Map<String, dynamic> _applyMigrations(
    Map<String, dynamic> data, 
    ModelVersion fromVersion, 
    ModelVersion toVersion
  ) {
    final migratedData = Map<String, dynamic>.from(data);
    
    // Migration from 1.0.0 to 1.1.0 (example)
    if (fromVersion.isNewerThan(const ModelVersion(1, 0, 0)) == false) {
      // Add default values for new fields
      migratedData['alertsEnabled'] ??= true;
      migratedData['photos'] ??= <String>[];
    }
    
    // Update version
    migratedData['_version'] = toVersion.toString();
    
    return migratedData;
  }

  /// Enhanced fromMap with validation
  factory FermentationLog.fromMapValidated(String id, Map<String, dynamic> map) {
    final log = FermentationLog.fromMap(id, map);
    final validation = log.validate();
    
    if (!validation.isValid) {
      AppLogger.error('FermentationLog validation failed: ${validation.errors}');
      // You might want to throw an exception or handle this differently
    }
    
    if (validation.warnings.isNotEmpty) {
      AppLogger.warning('FermentationLog validation warnings: ${validation.warnings}');
    }
    
    return log;
  }

  /// Enhanced toMap with version
  Map<String, dynamic> toMapWithVersion() {
    final map = toMap();
    map['_version'] = const ModelVersion(1, 0, 0).toString();
    return map;
  }
}