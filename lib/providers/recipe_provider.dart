import 'package:flutter/foundation.dart';
import '../repositories/recipes_repo.dart';
import '../repositories/ingredients_repo.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipesRepo _recipes;
  final IngredientsRepo _ingredients;
  
  List<Recipe> items = [];
  List<Recipe> filteredItems = [];
  List<Ingredient> allIngredients = [];
  List<String> favoriteIds = [];
  
  // Search and filter state
  String searchQuery = '';
  RecipeMethod? selectedMethod;
  bool standardOnly = false;
  bool showFavoritesOnly = false;
  
  // Loading states
  bool isLoading = false;
  String? error;

  RecipeProvider(this._recipes, this._ingredients) {
    _loadRecipes();
    _loadIngredients();
  }

  Future<void> _loadRecipes() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      
      _recipes.watchAll().listen((v) {
        items = v;
        _applyFilters();
        notifyListeners();
      });
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadIngredients() async {
    try {
      _ingredients.watchAll().listen((v) {
        allIngredients = v;
        notifyListeners();
      });
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter functionality
  void setMethodFilter(RecipeMethod? method) {
    selectedMethod = method;
    _applyFilters();
    notifyListeners();
  }

  void setStandardOnlyFilter(bool standardOnly) {
    this.standardOnly = standardOnly;
    _applyFilters();
    notifyListeners();
  }

  void setFavoritesOnlyFilter(bool favoritesOnly) {
    showFavoritesOnly = favoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    searchQuery = '';
    selectedMethod = null;
    standardOnly = false;
    showFavoritesOnly = false;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    filteredItems = items.where((recipe) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = recipe.name.toLowerCase().contains(query);
        final matchesCropTarget = recipe.cropTarget.toLowerCase().contains(query);
        final matchesDescription = recipe.description.toLowerCase().contains(query);
        final matchesIngredient = recipe.ingredients.any((ingredient) => 
          ingredient.name.toLowerCase().contains(query));
        
        if (!matchesName && !matchesCropTarget && !matchesDescription && !matchesIngredient) {
          return false;
        }
      }

      // Method filter
      if (selectedMethod != null && recipe.method != selectedMethod) {
        return false;
      }

      // Standard only filter
      if (standardOnly && !recipe.isStandard) {
        return false;
      }

      // Favorites only filter
      if (showFavoritesOnly && !favoriteIds.contains(recipe.id)) {
        return false;
      }

      return true;
    }).toList();
  }

  // Favorites functionality
  Future<void> loadFavorites(String userId) async {
    try {
      _recipes.watchFavoriteIds(userId: userId).listen((ids) {
        favoriteIds = ids;
        _applyFilters();
        notifyListeners();
      });
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String userId, String recipeId) async {
    try {
      await _recipes.toggleFavorite(userId: userId, recipeId: recipeId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String recipeId) {
    return favoriteIds.contains(recipeId);
  }

  // Recipe CRUD operations
  Future<void> createRecipe(Recipe recipe) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      
      await _recipes.createRecipe(recipe);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      
      await _recipes.updateRecipe(recipe);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      
      await _recipes.deleteRecipe(recipeId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Search by crop target
  Future<List<Recipe>> searchByCropTarget(String cropTarget) async {
    try {
      return await _recipes.searchByCropTarget(cropTarget);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Search by ingredient
  Future<List<Recipe>> searchByIngredient(String ingredientName) async {
    try {
      return await _recipes.searchByIngredient(ingredientName);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get popular recipes
  Future<List<Recipe>> getPopularRecipes() async {
    try {
      return await _recipes.getPopularRecipes();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get standard recipes
  Future<List<Recipe>> getStandardRecipes() async {
    try {
      return await _recipes.getStandardRecipes();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get recipes by method
  Future<List<Recipe>> getRecipesByMethod(RecipeMethod method) async {
    try {
      return await _recipes.getRecipesByMethod(method);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }
}