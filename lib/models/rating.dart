import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeRating {
  final String id;
  final String recipeId;
  final String userUid;
  final int stars; // 1-5
  final String? comment;
  final DateTime createdAt;

  const RecipeRating({
    required this.id,
    required this.recipeId,
    required this.userUid,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  static const String collectionPath = 'recipe_ratings';
  static String docPath(String id) => 'recipe_ratings/$id';
  static String recipeScopedPath(String recipeId) => 'recipes/$recipeId/ratings';

  factory RecipeRating.fromMap(String id, Map<String, dynamic> map) => RecipeRating(
        id: id,
        recipeId: map['recipeId'] ?? '',
        userUid: map['userUid'] ?? map['userId'] ?? '',
        stars: (map['stars'] ?? 0) as int,
        comment: map['comment'],
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory RecipeRating.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return RecipeRating.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'recipeId': recipeId,
        'userUid': userUid,
        'stars': stars,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  RecipeRating copyWith({
    String? recipeId,
    String? userUid,
    int? stars,
    String? comment,
    DateTime? createdAt,
  }) => RecipeRating(
        id: id,
        recipeId: recipeId ?? this.recipeId,
        userUid: userUid ?? this.userUid,
        stars: stars ?? this.stars,
        comment: comment ?? this.comment,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeRating &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recipeId == other.recipeId &&
          userUid == other.userUid &&
          stars == other.stars &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, recipeId, userUid, stars, comment, createdAt);
}