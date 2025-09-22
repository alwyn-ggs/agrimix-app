import '../models/ingredient.dart';
import '../models/nutrient_profile.dart';
import '../models/recipe.dart';
import '../repositories/ingredients_repo.dart';
import '../utils/logger.dart';

/// Service for analyzing nutrient content and providing recommendations for recipes
class AnalyticsService {
  final IngredientsRepo _ingredientsRepo;

  AnalyticsService(this._ingredientsRepo);

  /// Calculate the total nutrient profile for a recipe
  Future<NutrientProfile> calculateRecipeNutrients(List<RecipeIngredient> ingredients) async {
    try {
      NutrientProfile totalProfile = const NutrientProfile();
      
      for (final recipeIngredient in ingredients) {
        final ingredient = await _ingredientsRepo.getIngredient(recipeIngredient.ingredientId);
        if (ingredient?.nutrientProfile != null) {
          // Scale the nutrient profile by the amount used in the recipe
          final scaledProfile = ingredient!.nutrientProfile! * recipeIngredient.amount;
          totalProfile = totalProfile + scaledProfile;
        }
      }
      
      return totalProfile;
    } catch (e) {
      AppLogger.error('Error calculating recipe nutrients: $e', e);
      return const NutrientProfile();
    }
  }

  /// Get nutrient analysis for a recipe with recommendations
  Future<RecipeNutrientAnalysis> analyzeRecipe(List<RecipeIngredient> ingredients, String cropTarget) async {
    try {
      final totalNutrients = await calculateRecipeNutrients(ingredients);
      final recommendations = await getRecommendations(totalNutrients, cropTarget);
      final score = _calculateOverallScore(totalNutrients, cropTarget);
      
      return RecipeNutrientAnalysis(
        totalNutrients: totalNutrients,
        recommendations: recommendations,
        overallScore: score,
        cropTarget: cropTarget,
      );
    } catch (e) {
      AppLogger.error('Error analyzing recipe: $e', e);
      return RecipeNutrientAnalysis(
        totalNutrients: const NutrientProfile(),
        recommendations: [],
        overallScore: 0.0,
        cropTarget: cropTarget,
      );
    }
  }

  /// Get recommendations for improving a recipe based on nutrient analysis
  Future<List<NutrientRecommendation>> getRecommendations(NutrientProfile currentProfile, String cropTarget) async {
    try {
      final recommendations = <NutrientRecommendation>[];
      
      // Get ideal nutrient profile for the crop
      final idealProfile = _getIdealProfileForCrop(cropTarget);
      
      // Analyze deficiencies and suggest ingredients
      final deficiencies = _analyzeDeficiencies(currentProfile, idealProfile);
      
      for (final deficiency in deficiencies) {
        final suggestedIngredients = await _findIngredientsForDeficiency(deficiency);
        if (suggestedIngredients.isNotEmpty) {
          recommendations.add(NutrientRecommendation(
            type: deficiency.type,
            description: deficiency.description,
            suggestedIngredients: suggestedIngredients,
            priority: deficiency.priority,
          ));
        }
      }
      
      // Sort by priority (high priority first)
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));
      
      return recommendations;
    } catch (e) {
      AppLogger.error('Error getting recommendations: $e', e);
      return [];
    }
  }

  /// Find ingredients that can address a specific nutrient deficiency
  Future<List<IngredientSuggestion>> _findIngredientsForDeficiency(NutrientDeficiency deficiency) async {
    try {
      final allIngredients = await _ingredientsRepo.getAllIngredients();
      final suggestions = <IngredientSuggestion>[];
      
      for (final ingredient in allIngredients) {
        if (ingredient.nutrientProfile == null) continue;
        
        final profile = ingredient.nutrientProfile!;
        double relevance = 0.0;
        
        // Calculate relevance based on the deficiency type
        switch (deficiency.type) {
          case NutrientDeficiencyType.flowering:
            relevance = profile.floweringPromotion;
            break;
          case NutrientDeficiencyType.fruiting:
            relevance = profile.fruitingPromotion;
            break;
          case NutrientDeficiencyType.rootDevelopment:
            relevance = profile.rootDevelopment;
            break;
          case NutrientDeficiencyType.leafGrowth:
            relevance = profile.leafGrowth;
            break;
          case NutrientDeficiencyType.diseaseResistance:
            relevance = profile.diseaseResistance;
            break;
          case NutrientDeficiencyType.pestResistance:
            relevance = profile.pestResistance;
            break;
          case NutrientDeficiencyType.nitrogen:
            relevance = profile.nitrogen;
            break;
          case NutrientDeficiencyType.phosphorus:
            relevance = profile.phosphorus;
            break;
          case NutrientDeficiencyType.potassium:
            relevance = profile.potassium;
            break;
          case NutrientDeficiencyType.calcium:
            relevance = profile.calcium;
            break;
          case NutrientDeficiencyType.magnesium:
            relevance = profile.magnesium;
            break;
        }
        
        // Only suggest ingredients with significant relevance
        if (relevance > 0.3) {
          suggestions.add(IngredientSuggestion(
            ingredient: ingredient,
            relevance: relevance,
            suggestedAmount: _calculateSuggestedAmount(ingredient, deficiency),
            reason: _getSuggestionReason(ingredient, deficiency),
          ));
        }
      }
      
      // Sort by relevance and return top suggestions
      suggestions.sort((a, b) => b.relevance.compareTo(a.relevance));
      return suggestions.take(5).toList();
    } catch (e) {
      AppLogger.error('Error finding ingredients for deficiency: $e', e);
      return [];
    }
  }

  /// Calculate suggested amount for an ingredient based on deficiency
  double _calculateSuggestedAmount(Ingredient ingredient, NutrientDeficiency deficiency) {
    // Base amount on ingredient category and deficiency severity
    double baseAmount = 1.0;
    
    switch (ingredient.category.toLowerCase()) {
      case 'fruit':
        baseAmount = 2.0;
        break;
      case 'plant':
      case 'leaf':
        baseAmount = 1.5;
        break;
      case 'flower':
        baseAmount = 1.0;
        break;
      case 'root':
        baseAmount = 1.0;
        break;
      case 'fermentation aid':
        baseAmount = 0.5;
        break;
    }
    
    // Adjust based on deficiency severity
    return baseAmount * (1.0 + deficiency.severity);
  }

  /// Get reason for suggesting an ingredient
  String _getSuggestionReason(Ingredient ingredient, NutrientDeficiency deficiency) {
    final profile = ingredient.nutrientProfile!;
    
    switch (deficiency.type) {
      case NutrientDeficiencyType.flowering:
        return 'High flowering promotion (${(profile.floweringPromotion * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.fruiting:
        return 'High fruiting promotion (${(profile.fruitingPromotion * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.rootDevelopment:
        return 'Promotes root development (${(profile.rootDevelopment * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.leafGrowth:
        return 'Promotes leaf growth (${(profile.leafGrowth * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.diseaseResistance:
        return 'Improves disease resistance (${(profile.diseaseResistance * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.pestResistance:
        return 'Improves pest resistance (${(profile.pestResistance * 100).toStringAsFixed(0)}%)';
      case NutrientDeficiencyType.nitrogen:
        return 'Rich in nitrogen (${profile.nitrogen.toStringAsFixed(1)})';
      case NutrientDeficiencyType.phosphorus:
        return 'Rich in phosphorus (${profile.phosphorus.toStringAsFixed(1)})';
      case NutrientDeficiencyType.potassium:
        return 'Rich in potassium (${profile.potassium.toStringAsFixed(1)})';
      case NutrientDeficiencyType.calcium:
        return 'Rich in calcium (${profile.calcium.toStringAsFixed(1)})';
      case NutrientDeficiencyType.magnesium:
        return 'Rich in magnesium (${profile.magnesium.toStringAsFixed(1)})';
    }
  }

  /// Analyze nutrient deficiencies compared to ideal profile
  List<NutrientDeficiency> _analyzeDeficiencies(NutrientProfile current, NutrientProfile ideal) {
    final deficiencies = <NutrientDeficiency>[];
    
    // Check plant benefit deficiencies
    if (current.floweringPromotion < ideal.floweringPromotion * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.flowering,
        description: 'Low flowering promotion - add ingredients that promote blooming',
        severity: (ideal.floweringPromotion - current.floweringPromotion) / ideal.floweringPromotion,
        priority: 3,
      ));
    }
    
    if (current.fruitingPromotion < ideal.fruitingPromotion * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.fruiting,
        description: 'Low fruiting promotion - add ingredients that promote fruit development',
        severity: (ideal.fruitingPromotion - current.fruitingPromotion) / ideal.fruitingPromotion,
        priority: 3,
      ));
    }
    
    if (current.rootDevelopment < ideal.rootDevelopment * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.rootDevelopment,
        description: 'Low root development - add ingredients that promote root growth',
        severity: (ideal.rootDevelopment - current.rootDevelopment) / ideal.rootDevelopment,
        priority: 2,
      ));
    }
    
    if (current.leafGrowth < ideal.leafGrowth * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.leafGrowth,
        description: 'Low leaf growth - add ingredients that promote leaf development',
        severity: (ideal.leafGrowth - current.leafGrowth) / ideal.leafGrowth,
        priority: 2,
      ));
    }
    
    if (current.diseaseResistance < ideal.diseaseResistance * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.diseaseResistance,
        description: 'Low disease resistance - add ingredients that improve plant immunity',
        severity: (ideal.diseaseResistance - current.diseaseResistance) / ideal.diseaseResistance,
        priority: 2,
      ));
    }
    
    // Check macronutrient deficiencies
    if (current.nitrogen < ideal.nitrogen * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.nitrogen,
        description: 'Low nitrogen - add ingredients rich in nitrogen for leaf growth',
        severity: (ideal.nitrogen - current.nitrogen) / ideal.nitrogen,
        priority: 1,
      ));
    }
    
    if (current.phosphorus < ideal.phosphorus * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.phosphorus,
        description: 'Low phosphorus - add ingredients rich in phosphorus for flowering and root development',
        severity: (ideal.phosphorus - current.phosphorus) / ideal.phosphorus,
        priority: 1,
      ));
    }
    
    if (current.potassium < ideal.potassium * 0.7) {
      deficiencies.add(NutrientDeficiency(
        type: NutrientDeficiencyType.potassium,
        description: 'Low potassium - add ingredients rich in potassium for fruit development',
        severity: (ideal.potassium - current.potassium) / ideal.potassium,
        priority: 1,
      ));
    }
    
    return deficiencies;
  }

  /// Get ideal nutrient profile for a specific crop
  NutrientProfile _getIdealProfileForCrop(String cropTarget) {
    final crop = cropTarget.toLowerCase();
    
    // Define ideal profiles for different crops
    if (crop.contains('tomato') || crop.contains('pepper') || crop.contains('eggplant')) {
      // Fruiting vegetables - need high phosphorus and potassium for flowering/fruiting
      return const NutrientProfile(
        nitrogen: 2.0,
        phosphorus: 3.0,
        potassium: 3.0,
        calcium: 2.0,
        floweringPromotion: 0.8,
        fruitingPromotion: 0.9,
        rootDevelopment: 0.7,
        leafGrowth: 0.6,
        diseaseResistance: 0.7,
        pestResistance: 0.6,
      );
    } else if (crop.contains('leafy') || crop.contains('kangkong') || crop.contains('malunggay')) {
      // Leafy vegetables - need high nitrogen for leaf growth
      return const NutrientProfile(
        nitrogen: 3.0,
        phosphorus: 2.0,
        potassium: 2.0,
        calcium: 2.5,
        floweringPromotion: 0.3,
        fruitingPromotion: 0.2,
        rootDevelopment: 0.6,
        leafGrowth: 0.9,
        diseaseResistance: 0.6,
        pestResistance: 0.5,
      );
    } else if (crop.contains('rice') || crop.contains('corn')) {
      // Grain crops - need balanced nutrients
      return const NutrientProfile(
        nitrogen: 2.5,
        phosphorus: 2.5,
        potassium: 2.5,
        calcium: 1.5,
        floweringPromotion: 0.7,
        fruitingPromotion: 0.8,
        rootDevelopment: 0.8,
        leafGrowth: 0.7,
        diseaseResistance: 0.8,
        pestResistance: 0.7,
      );
    } else {
      // Default balanced profile
      return const NutrientProfile(
        nitrogen: 2.0,
        phosphorus: 2.0,
        potassium: 2.0,
        calcium: 1.5,
        floweringPromotion: 0.6,
        fruitingPromotion: 0.6,
        rootDevelopment: 0.6,
        leafGrowth: 0.6,
        diseaseResistance: 0.6,
        pestResistance: 0.6,
      );
    }
  }

  /// Calculate overall score for a recipe (0-100)
  double _calculateOverallScore(NutrientProfile profile, String cropTarget) {
    final ideal = _getIdealProfileForCrop(cropTarget);
    
    // Calculate scores for different aspects
    final npkScore = _calculateNPKScore(profile, ideal);
    final benefitScore = _calculateBenefitScore(profile, ideal);
    
    // Weighted average (NPK 60%, benefits 40%)
    return (npkScore * 0.6) + (benefitScore * 0.4);
  }

  /// Calculate NPK score (0-100)
  double _calculateNPKScore(NutrientProfile current, NutrientProfile ideal) {
    final nScore = (current.nitrogen / ideal.nitrogen).clamp(0.0, 1.0) * 100;
    final pScore = (current.phosphorus / ideal.phosphorus).clamp(0.0, 1.0) * 100;
    final kScore = (current.potassium / ideal.potassium).clamp(0.0, 1.0) * 100;
    
    return (nScore + pScore + kScore) / 3.0;
  }

  /// Calculate plant benefit score (0-100)
  double _calculateBenefitScore(NutrientProfile current, NutrientProfile ideal) {
    final floweringScore = (current.floweringPromotion / ideal.floweringPromotion).clamp(0.0, 1.0) * 100;
    final fruitingScore = (current.fruitingPromotion / ideal.fruitingPromotion).clamp(0.0, 1.0) * 100;
    final rootScore = (current.rootDevelopment / ideal.rootDevelopment).clamp(0.0, 1.0) * 100;
    final leafScore = (current.leafGrowth / ideal.leafGrowth).clamp(0.0, 1.0) * 100;
    final diseaseScore = (current.diseaseResistance / ideal.diseaseResistance).clamp(0.0, 1.0) * 100;
    
    return (floweringScore + fruitingScore + rootScore + leafScore + diseaseScore) / 5.0;
  }
}

/// Analysis result for a recipe's nutrient content
class RecipeNutrientAnalysis {
  final NutrientProfile totalNutrients;
  final List<NutrientRecommendation> recommendations;
  final double overallScore;
  final String cropTarget;

  const RecipeNutrientAnalysis({
    required this.totalNutrients,
    required this.recommendations,
    required this.overallScore,
    required this.cropTarget,
  });
}

/// Recommendation for improving a recipe
class NutrientRecommendation {
  final NutrientDeficiencyType type;
  final String description;
  final List<IngredientSuggestion> suggestedIngredients;
  final int priority; // 1 = high, 2 = medium, 3 = low

  const NutrientRecommendation({
    required this.type,
    required this.description,
    required this.suggestedIngredients,
    required this.priority,
  });
}

/// Suggestion for a specific ingredient
class IngredientSuggestion {
  final Ingredient ingredient;
  final double relevance; // 0.0 to 1.0
  final double suggestedAmount;
  final String reason;

  const IngredientSuggestion({
    required this.ingredient,
    required this.relevance,
    required this.suggestedAmount,
    required this.reason,
  });
}

/// Types of nutrient deficiencies
enum NutrientDeficiencyType {
  flowering,
  fruiting,
  rootDevelopment,
  leafGrowth,
  diseaseResistance,
  pestResistance,
  nitrogen,
  phosphorus,
  potassium,
  calcium,
  magnesium,
}

/// Represents a nutrient deficiency
class NutrientDeficiency {
  final NutrientDeficiencyType type;
  final String description;
  final double severity; // 0.0 to 1.0
  final int priority; // 1 = high, 2 = medium, 3 = low

  const NutrientDeficiency({
    required this.type,
    required this.description,
    required this.severity,
    required this.priority,
  });
}
