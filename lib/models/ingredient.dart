import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrient_profile.dart';
import '../utils/validation.dart';
import '../utils/logger.dart';

class Ingredient {
  final String id;
  final String name;
  final String category;
  final String? description;
  final List<String> recommendedFor; // crops list
  final List<String> precautions;
  final NutrientProfile? nutrientProfile; // Nutritional and plant benefit data
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.recommendedFor,
    required this.precautions,
    this.nutrientProfile,
    required this.createdAt,
  });

  static const String collectionPath = 'ingredients';
  static String docPath(String id) => 'ingredients/$id';

  factory Ingredient.fromMap(String id, Map<String, dynamic> map) => Ingredient(
        id: id,
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        description: map['description'],
        recommendedFor: List<String>.from(map['recommendedFor'] ?? const <String>[]),
        precautions: List<String>.from(map['precautions'] ?? const <String>[]),
        nutrientProfile: map['nutrientProfile'] != null 
            ? NutrientProfile.fromMap(Map<String, dynamic>.from(map['nutrientProfile']))
            : null,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory Ingredient.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Ingredient.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'description': description,
        'recommendedFor': recommendedFor,
        'precautions': precautions,
        'nutrientProfile': nutrientProfile?.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Ingredient copyWith({
    String? name,
    String? category,
    String? description,
    List<String>? recommendedFor,
    List<String>? precautions,
    NutrientProfile? nutrientProfile,
    DateTime? createdAt,
  }) => Ingredient(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        recommendedFor: recommendedFor ?? this.recommendedFor,
        precautions: precautions ?? this.precautions,
        nutrientProfile: nutrientProfile ?? this.nutrientProfile,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          description == other.description &&
          _listEquals(recommendedFor, other.recommendedFor) &&
          _listEquals(precautions, other.precautions) &&
          nutrientProfile == other.nutrientProfile &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
      id, name, category, description, Object.hashAll(recommendedFor), Object.hashAll(precautions), nutrientProfile, createdAt);

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Validate ingredient
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate name
    results.add(ValidationUtils.validateRequiredString(name, 'Name'));
    results.add(ValidationUtils.validateStringLength(name, 'Name', minLength: 1, maxLength: 100));

    // Validate category
    results.add(ValidationUtils.validateRequiredString(category, 'Category'));
    results.add(ValidationUtils.validateStringLength(category, 'Category', minLength: 1, maxLength: 50));

    // Validate description (optional)
    if (description != null && description!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(description!, 'Description', minLength: 1, maxLength: 1000));
    }

    // Validate recommended for crops
    results.add(ValidationUtils.validateListLength(recommendedFor, 'Recommended for', maxLength: 50));
    for (int i = 0; i < recommendedFor.length; i++) {
      if (recommendedFor[i].trim().isEmpty) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Recommended crop ${i + 1}: Cannot be empty'],
        ));
      } else if (recommendedFor[i].length > 100) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Recommended crop ${i + 1}: Cannot exceed 100 characters'],
        ));
      }
    }

    // Validate precautions
    results.add(ValidationUtils.validateListLength(precautions, 'Precautions', maxLength: 20));
    for (int i = 0; i < precautions.length; i++) {
      if (precautions[i].trim().isEmpty) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Precaution ${i + 1}: Cannot be empty'],
        ));
      } else if (precautions[i].length > 500) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Precaution ${i + 1}: Cannot exceed 500 characters'],
        ));
      }
    }

    // Validate nutrient profile (optional)
    if (nutrientProfile != null) {
      // Assuming NutrientProfile has a validate method
      // You might need to implement this in the NutrientProfile class
      // final profileResult = nutrientProfile!.validate();
      // if (!profileResult.isValid) {
      //   results.add(ValidationResult(
      //     isValid: false,
      //     errors: profileResult.errors.map((e) => 'Nutrient profile: $e').toList(),
      //   ));
      // }
    }

    // Validate created date
    final now = DateTime.now();
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created date', maxDate: now));

    return ValidationResult.combine(results);
  }

  /// Check if ingredient is valid (convenience method)
  bool get isValid => validate().isValid;

  /// Get validation errors (convenience method)
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings (convenience method)
  List<String> get validationWarnings => validate().warnings;

  /// Enhanced fromMap with validation
  factory Ingredient.fromMapValidated(String id, Map<String, dynamic> map) {
    final ingredient = Ingredient.fromMap(id, map);
    final validation = ingredient.validate();

    if (!validation.isValid) {
      AppLogger.error('Ingredient validation failed: ${validation.errors}');
    }

    if (validation.warnings.isNotEmpty) {
      AppLogger.warning('Ingredient validation warnings: ${validation.warnings}');
    }

    return ingredient;
  }

  /// Enhanced toMap with version
  Map<String, dynamic> toMapWithVersion() {
    final map = toMap();
    map['_version'] = const ModelVersion(1, 0, 0).toString();
    return map;
  }
}