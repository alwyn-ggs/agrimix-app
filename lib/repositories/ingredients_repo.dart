import '../services/firestore_service.dart';
import '../models/ingredient.dart';

class IngredientsRepo {
  final FirestoreService _fs;

  IngredientsRepo(this._fs);

  // CRUD Operations
  Future<void> createIngredient(Ingredient ingredient) async {
    try {
      await _fs.createDocument(Ingredient.collectionPath, ingredient.id, ingredient.toMap());
    } catch (e) {
      throw Exception('Failed to create ingredient: $e');
    }
  }

  // Get ingredients by ids
  Future<List<Ingredient>> getIngredientsByIds(List<String> ids) async {
    if (ids.isEmpty) return <Ingredient>[];
    try {
      final all = await getAllIngredients(limit: 500);
      final idSet = ids.toSet();
      return all.where((i) => idSet.contains(i.id)).toList();
    } catch (e) {
      throw Exception('Failed to get ingredients by ids: $e');
    }
  }

  // Suggest ingredients for FFJ/FPJ by simple heuristic on category/name
  Future<List<Ingredient>> suggestForMethod({required bool isFPJ, int limit = 30}) async {
    try {
      final all = await getAllIngredients(limit: 500);
      final lower = all.map((i) => i).toList();

      bool matches(Ingredient i) {
        final name = i.name.toLowerCase();
        final cat = i.category.toLowerCase();
        if (isFPJ) {
          // FPJ typically uses fast-growing plant tips and weeds
          return cat.contains('plant') || cat.contains('leaf') || cat.contains('weed') ||
              name.contains('young') || name.contains('leaf') || name.contains('tip');
        } else {
          // FFJ typically uses ripe fruits/flowers
          return cat.contains('fruit') || cat.contains('flower') ||
              name.contains('fruit') || name.contains('flower') || name.contains('banana') || name.contains('papaya');
        }
      }

      final filtered = lower.where(matches).take(limit).toList();
      return filtered.isEmpty ? all.take(limit).toList() : filtered;
    } catch (e) {
      throw Exception('Failed to suggest ingredients: $e');
    }
  }

  Future<Ingredient?> getIngredient(String ingredientId) async {
    try {
      final doc = await _fs.getDocument(Ingredient.collectionPath, ingredientId);
      if (doc.exists) {
        return Ingredient.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ingredient: $e');
    }
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _fs.updateDocument(Ingredient.collectionPath, ingredient.id, ingredient.toMap());
    } catch (e) {
      throw Exception('Failed to update ingredient: $e');
    }
  }

  Future<void> deleteIngredient(String ingredientId) async {
    try {
      await _fs.deleteDocument(Ingredient.collectionPath, ingredientId);
    } catch (e) {
      throw Exception('Failed to delete ingredient: $e');
    }
  }

  // Get all ingredients
  Future<List<Ingredient>> getAllIngredients({int limit = 100}) async {
    try {
      final docs = await _fs.getDocuments(
        Ingredient.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      );

      return docs.map((doc) => Ingredient.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get all ingredients: $e');
    }
  }

  // Real-time stream
  Stream<List<Ingredient>> watchIngredients({int? limit}) {
    try {
      return _fs.watchDocuments(
        Ingredient.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      ).map((docs) => docs.map((doc) => Ingredient.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch ingredients: $e');
    }
  }

  // Legacy method for backward compatibility
  Stream<List<Ingredient>> watchAll() => watchIngredients();

  // Search ingredients by name
  Future<List<Ingredient>> searchIngredients(String searchTerm, {int limit = 20}) async {
    try {
      final docs = await _fs.searchDocuments(
        Ingredient.collectionPath,
        'name',
        searchTerm,
        limit: limit,
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      );

      return docs.map((doc) => Ingredient.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to search ingredients: $e');
    }
  }

  // Get ingredients by category
  Future<List<Ingredient>> getIngredientsByCategory(String category, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Ingredient.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'category', value: category)],
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      );

      return docs.map((doc) => Ingredient.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get ingredients by category: $e');
    }
  }

  // Get ingredients recommended for a specific crop
  Future<List<Ingredient>> getIngredientsForCrop(String cropName, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Ingredient.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'name', descending: false)],
      );

      final ingredients = docs.map((doc) => Ingredient.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter ingredients that are recommended for the crop
      return ingredients.where((ingredient) => 
        ingredient.recommendedFor.any((crop) => 
          crop.toLowerCase().contains(cropName.toLowerCase())
        )
      ).toList();
    } catch (e) {
      throw Exception('Failed to get ingredients for crop: $e');
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      final ingredients = await getAllIngredients();
      final categories = ingredients.map((ingredient) => ingredient.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Get all recommended crops
  Future<List<String>> getRecommendedCrops() async {
    try {
      final ingredients = await getAllIngredients();
      final crops = <String>{};
      for (final ingredient in ingredients) {
        crops.addAll(ingredient.recommendedFor);
      }
      final cropList = crops.toList();
      cropList.sort();
      return cropList;
    } catch (e) {
      throw Exception('Failed to get recommended crops: $e');
    }
  }

  // Batch create ingredients
  Future<void> batchCreateIngredients(List<Ingredient> ingredients) async {
    try {
      print('Starting batch create for ${ingredients.length} ingredients...');
      
      // Create ingredients in smaller batches to avoid timeout
      const batchSize = 10;
      for (int i = 0; i < ingredients.length; i += batchSize) {
        final batch = _fs.batch();
        final endIndex = (i + batchSize < ingredients.length) ? i + batchSize : ingredients.length;
        final batchIngredients = ingredients.sublist(i, endIndex);
        
        print('Processing batch ${(i ~/ batchSize) + 1}: ingredients ${i + 1}-$endIndex');
        
        for (final ingredient in batchIngredients) {
          final docRef = _fs.db.collection(Ingredient.collectionPath).doc(ingredient.id);
          batch.set(docRef, ingredient.toMap());
        }
        
        await batch.commit();
        print('Batch ${(i ~/ batchSize) + 1} committed successfully');
      }
      
      print('All batches committed successfully');
    } catch (e) {
      print('Error in batch create: $e');
      throw Exception('Failed to batch create ingredients: $e');
    }
  }

  // Get ingredient statistics
  Future<Map<String, int>> getIngredientStats() async {
    try {
      final ingredients = await getAllIngredients();
      final stats = <String, int>{
        'total': ingredients.length,
        'categories': ingredients.map((i) => i.category).toSet().length,
        'crops': ingredients.expand((i) => i.recommendedFor).toSet().length,
      };
      return stats;
    } catch (e) {
      throw Exception('Failed to get ingredient stats: $e');
    }
  }
}