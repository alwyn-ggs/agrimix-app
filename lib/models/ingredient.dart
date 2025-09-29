import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrient_profile.dart';

class Ingredient {
  final String id;
  final String name;
  final String category;
  final String? description;
  final List<String> recommendedFor; // crops list
  final List<String> precautions;
  final NutrientProfile? nutrientProfile; // Nutritional and plant benefit data
  final DateTime createdAt;

  Ingredient({
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
}