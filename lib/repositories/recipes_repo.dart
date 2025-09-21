import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/recipe.dart';

class RecipesRepo {
  final FirestoreService _fs;
  final StorageService storage;

  RecipesRepo(this._fs, this.storage);

  // CRUD Operations
  Future<void> createRecipe(Recipe recipe) async {
    try {
      await _fs.createDocument(Recipe.collectionPath, recipe.id, recipe.toMap());
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  Future<Recipe?> getRecipe(String recipeId) async {
    try {
      final doc = await _fs.getDocument(Recipe.collectionPath, recipeId);
      if (doc.exists) {
        return Recipe.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _fs.updateDocument(Recipe.collectionPath, recipe.id, recipe.toMap());
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _fs.deleteDocument(Recipe.collectionPath, recipeId);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  // Get all recipes (for My Recipes tab)
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );
      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get all recipes: $e');
    }
  }

  // Pagination
  Future<List<Recipe>> getRecipes({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? ownerUid,
    RecipeMethod? method,
    RecipeVisibility? visibility,
    bool? isStandard,
  }) async {
    try {
      final where = <QueryFilter>[];
      if (ownerUid != null) where.add(QueryFilter(field: 'ownerUid', value: ownerUid));
      if (method != null) where.add(QueryFilter(field: 'method', value: method == RecipeMethod.fpj ? 'fpj' : 'ffj'));
      if (visibility != null) where.add(QueryFilter(field: 'visibility', value: visibility == RecipeVisibility.private ? 'private' : 'public'));
      if (isStandard != null) where.add(QueryFilter(field: 'isStandard', value: isStandard));

      final orderBy = [const QueryOrder(field: 'createdAt', descending: true)];

      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        startAfter: startAfter,
        where: where,
        orderBy: orderBy,
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get recipes: $e');
    }
  }

  // Real-time streams
  Stream<List<Recipe>> watchRecipes({
    int? limit,
    String? ownerUid,
    RecipeMethod? method,
    RecipeVisibility? visibility,
    bool? isStandard,
  }) {
    try {
      final where = <QueryFilter>[];
      if (ownerUid != null) where.add(QueryFilter(field: 'ownerUid', value: ownerUid));
      if (method != null) where.add(QueryFilter(field: 'method', value: method == RecipeMethod.fpj ? 'fpj' : 'ffj'));
      if (visibility != null) where.add(QueryFilter(field: 'visibility', value: visibility == RecipeVisibility.private ? 'private' : 'public'));
      if (isStandard != null) where.add(QueryFilter(field: 'isStandard', value: isStandard));

      final orderBy = [const QueryOrder(field: 'createdAt', descending: true)];

      return _fs.watchDocuments(
        Recipe.collectionPath,
        limit: limit,
        where: where,
        orderBy: orderBy,
      ).map((docs) => docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch recipes: $e');
    }
  }

  // Legacy method for backward compatibility
  Stream<List<Recipe>> watchAll() => watchRecipes();

  // Search by crop target
  Future<List<Recipe>> searchByCropTarget(String cropTarget, {int limit = 20}) async {
    try {
      final docs = await _fs.searchDocuments(
        Recipe.collectionPath,
        'cropTarget',
        cropTarget,
        limit: limit,
        orderBy: [const QueryOrder(field: 'avgRating', descending: true)],
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to search recipes by crop target: $e');
    }
  }

  // Search by ingredient
  Future<List<Recipe>> searchByIngredient(String ingredientName, {int limit = 20}) async {
    try {
      // This is a simplified search - for complex ingredient matching,
      // you might want to use array-contains or implement a more sophisticated search
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'avgRating', descending: true)],
      );

      final recipes = docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter recipes that contain the ingredient
      return recipes.where((recipe) => 
        recipe.ingredients.any((ingredient) => 
          ingredient.name.toLowerCase().contains(ingredientName.toLowerCase())
        )
      ).toList();
    } catch (e) {
      throw Exception('Failed to search recipes by ingredient: $e');
    }
  }

  // Get popular recipes
  Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    try {
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        orderBy: [
          const QueryOrder(field: 'likes', descending: true),
          const QueryOrder(field: 'avgRating', descending: true),
        ],
        where: [const QueryFilter(field: 'visibility', value: 'public')],
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get popular recipes: $e');
    }
  }

  // Get user's recipes
  Future<List<Recipe>> getUserRecipes(String userId, {int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        startAfter: startAfter,
        where: [QueryFilter(field: 'ownerUid', value: userId)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get user recipes: $e');
    }
  }


  // Rate recipe
  Future<void> rateRecipe(String recipeId, String userId, double rating, {String? comment}) async {
    try {
      await _fs.runTransaction((transaction) async {
        final recipeRef = _fs.db.collection(Recipe.collectionPath).doc(recipeId);
        final ratingRef = _fs.db.collection(Recipe.ratingsSubcollectionPath(recipeId)).doc(userId);
        
        // Update or create rating
        transaction.set(ratingRef, {
          'userId': userId,
          'rating': rating,
          if (comment != null) 'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Recalculate average rating and total ratings count
        final ratingsSnapshot = await _fs.db
            .collection(Recipe.ratingsSubcollectionPath(recipeId))
            .get();
        
        if (ratingsSnapshot.docs.isNotEmpty) {
          final totalRating = ratingsSnapshot.docs
              .map((doc) => (doc.data()['rating'] as num).toDouble())
              .reduce((a, b) => a + b);
          final avgRating = totalRating / ratingsSnapshot.docs.length;
          
          transaction.update(recipeRef, {
            'avgRating': avgRating,
            'totalRatings': ratingsSnapshot.docs.length,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to rate recipe: $e');
    }
  }

  // Get recipe rating
  Future<double?> getRecipeRating(String recipeId, String userId) async {
    try {
      final doc = await _fs.getDocument(Recipe.ratingsSubcollectionPath(recipeId), userId);
      if (doc.exists) {
        return (doc.data()!['rating'] as num).toDouble();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get recipe rating: $e');
    }
  }

  // Watch ratings/comments for a recipe
  Stream<List<Map<String, dynamic>>> watchRecipeRatingsRaw(String recipeId) {
    return _fs.db
        .collection(Recipe.ratingsSubcollectionPath(recipeId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  // Upload recipe image
  Future<String> uploadRecipeImage(String recipeId, String userId, File imageFile) async {
    try {
      return await storage.uploadRecipeImage(
        imageFile: imageFile,
        userId: userId,
        recipeId: recipeId,
      );
    } catch (e) {
      throw Exception('Failed to upload recipe image: $e');
    }
  }

  // Favorites: users/{uid}/favorites/{recipeId}
  Future<void> toggleFavorite({required String userId, required String recipeId}) async {
    try {
      final favRef = _fs.db.collection('users').doc(userId).collection('favorites').doc(recipeId);
      final snap = await favRef.get();
      if (snap.exists) {
        await favRef.delete();
      } else {
        await favRef.set({
          'recipeId': recipeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Stream<bool> watchIsFavorite({required String userId, required String recipeId}) {
    return _fs.db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> watchFavoriteIds({required String userId}) {
    return _fs.db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
  }

  Future<List<String>> getFavoriteIds({required String userId}) async {
    try {
      final snapshot = await _fs.db
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get favorite IDs: $e');
    }
  }

  // Get standard recipes
  Future<List<Recipe>> getStandardRecipes({int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        where: [const QueryFilter(field: 'isStandard', value: true)],
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get standard recipes: $e');
    }
  }

  // Get recipes by method
  Future<List<Recipe>> getRecipesByMethod(RecipeMethod method, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Recipe.collectionPath,
        limit: limit,
        where: [
          QueryFilter(field: 'method', value: method == RecipeMethod.fpj ? 'fpj' : 'ffj'),
          const QueryFilter(field: 'visibility', value: 'public'),
        ],
        orderBy: [const QueryOrder(field: 'avgRating', descending: true)],
      );

      return docs.map((doc) => Recipe.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get recipes by method: $e');
    }
  }

}