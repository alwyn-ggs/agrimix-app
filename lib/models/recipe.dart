import 'package:cloud_firestore/cloud_firestore.dart';

enum RecipeMethod { FFJ, FPJ }
enum RecipeVisibility { public, private }

class RecipeIngredient {
  final String ingredientId;
  final String name;
  final double amount;
  final String unit;

  const RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) => RecipeIngredient(
        ingredientId: map['ingredientId'] ?? '',
        name: map['name'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'name': name,
        'amount': amount,
        'unit': unit,
      };

  RecipeIngredient copyWith({
    String? ingredientId,
    String? name,
    double? amount,
    String? unit,
  }) => RecipeIngredient(
        ingredientId: ingredientId ?? this.ingredientId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
      );
}

class RecipeStep {
  final int order;
  final String text;

  const RecipeStep({
    required this.order,
    required this.text,
  });

  factory RecipeStep.fromMap(Map<String, dynamic> map) => RecipeStep(
        order: (map['order'] ?? 0) as int,
        text: map['text'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'order': order,
        'text': text,
      };
}

class Recipe {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final RecipeMethod method;
  final String cropTarget;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeVisibility visibility;
  final bool isStandard;
  final int likes;
  final double avgRating;
  final int totalRatings;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.method,
    required this.cropTarget,
    required this.ingredients,
    required this.steps,
    required this.visibility,
    required this.isStandard,
    required this.likes,
    required this.avgRating,
    required this.totalRatings,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String collectionPath = 'recipes';
  static String docPath(String recipeId) => 'recipes/$recipeId';
  static String ratingsSubcollectionPath(String recipeId) => 'recipes/$recipeId/ratings';

  factory Recipe.fromMap(String id, Map<String, dynamic> map) => Recipe(
        id: id,
        ownerUid: map['ownerUid'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        method: (map['method'] == 'FPJ') ? RecipeMethod.FPJ : RecipeMethod.FFJ,
        cropTarget: map['cropTarget'] ?? '',
        ingredients: (map['ingredients'] as List?)
                ?.map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const <RecipeIngredient>[],
        steps: (map['steps'] as List?)
                ?.map((e) => RecipeStep.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const <RecipeStep>[],
        visibility: (map['visibility'] == 'private') ? RecipeVisibility.private : RecipeVisibility.public,
        isStandard: (map['isStandard'] ?? false) as bool,
        likes: (map['likes'] ?? 0) as int,
        avgRating: (map['avgRating'] is num) ? (map['avgRating'] as num).toDouble() : 0.0,
        totalRatings: (map['totalRatings'] ?? 0) as int,
        imageUrls: (map['imageUrls'] as List?)?.map((e) => e as String).toList() ?? const <String>[],
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory Recipe.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Recipe.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'description': description,
        'method': method == RecipeMethod.FPJ ? 'FPJ' : 'FFJ',
        'cropTarget': cropTarget,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'steps': steps.map((e) => e.toMap()).toList(),
        'visibility': visibility == RecipeVisibility.private ? 'private' : 'public',
        'isStandard': isStandard,
        'likes': likes,
        'avgRating': avgRating,
        'totalRatings': totalRatings,
        'imageUrls': imageUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Recipe copyWith({
    String? ownerUid,
    String? name,
    String? description,
    RecipeMethod? method,
    String? cropTarget,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
    RecipeVisibility? visibility,
    bool? isStandard,
    int? likes,
    double? avgRating,
    int? totalRatings,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Recipe(
        id: id,
        ownerUid: ownerUid ?? this.ownerUid,
        name: name ?? this.name,
        description: description ?? this.description,
        method: method ?? this.method,
        cropTarget: cropTarget ?? this.cropTarget,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        visibility: visibility ?? this.visibility,
        isStandard: isStandard ?? this.isStandard,
        likes: likes ?? this.likes,
        avgRating: avgRating ?? this.avgRating,
        totalRatings: totalRatings ?? this.totalRatings,
        imageUrls: imageUrls ?? this.imageUrls,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerUid == other.ownerUid &&
          name == other.name &&
          description == other.description &&
          method == other.method &&
          cropTarget == other.cropTarget &&
          _listEquals(ingredients, other.ingredients) &&
          _listEquals(steps, other.steps) &&
          visibility == other.visibility &&
          isStandard == other.isStandard &&
          likes == other.likes &&
          avgRating == other.avgRating &&
          totalRatings == other.totalRatings &&
          _listEquals(imageUrls, other.imageUrls) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        ownerUid,
        name,
        description,
        method,
        cropTarget,
        Object.hashAll(ingredients.map((e) => Object.hash(e.ingredientId, e.name, e.amount, e.unit))),
        Object.hashAll(steps.map((e) => Object.hash(e.order, e.text))),
        visibility,
        isStandard,
        likes,
        avgRating,
        totalRatings,
        Object.hashAll(imageUrls),
        createdAt,
        updatedAt,
      );

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}