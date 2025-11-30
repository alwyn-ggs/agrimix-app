import 'package:agrimix/models/ingredient.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../models/nutrient_profile.dart';
import '../../services/analytics_service.dart';
import '../../repositories/ingredients_repo.dart';
import '../../theme/theme.dart';

class RecipeAnalyticsWidget extends StatefulWidget {
  final List<RecipeIngredient> ingredients;
  final String cropTarget;
  final double batchSize;
  final Function(List<RecipeIngredient>)? onIngredientsUpdated;

  const RecipeAnalyticsWidget({
    super.key,
    required this.ingredients,
    required this.cropTarget,
    this.batchSize = 3.0,
    this.onIngredientsUpdated,
  });

  @override
  State<RecipeAnalyticsWidget> createState() => _RecipeAnalyticsWidgetState();
}

class _RecipeAnalyticsWidgetState extends State<RecipeAnalyticsWidget> {
  RecipeNutrientAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeRecipe();
  }

  @override
  void didUpdateWidget(RecipeAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredients != widget.ingredients || 
        oldWidget.cropTarget != widget.cropTarget) {
      _analyzeRecipe();
    }
  }

  Future<void> _analyzeRecipe() async {
    if (widget.ingredients.isEmpty) {
      setState(() {
        _analysis = null;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use real ingredient nutrient profiles
      final totalNutrients = await _calculateRealNutrients();
      final recommendations = _generateRecommendations(totalNutrients);
      final score = _calculateScore(totalNutrients);
      
      final analysis = RecipeNutrientAnalysis(
        totalNutrients: totalNutrients,
        recommendations: recommendations,
        overallScore: score,
        cropTarget: widget.cropTarget,
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Calculate real nutrient totals from ingredient profiles
  Future<NutrientProfile> _calculateRealNutrients() async {
    final ingredientsRepo = context.read<IngredientsRepo>();
    NutrientProfile totalProfile = const NutrientProfile();

    for (final recipeIngredient in widget.ingredients) {
      try {
        final ingredient = await ingredientsRepo.getIngredient(recipeIngredient.ingredientId);
        if (ingredient?.nutrientProfile != null) {
          // Scale the nutrient profile by the amount used in the recipe
          final scaledProfile = ingredient!.nutrientProfile! * recipeIngredient.amount;
          totalProfile = totalProfile + scaledProfile;
        }
      } catch (e) {
        // Continue with other ingredients if one fails
        continue;
      }
    }

    return totalProfile;
  }

  List<NutrientRecommendation> _generateRecommendations(NutrientProfile profile) {
    final recommendations = <NutrientRecommendation>[];
    
    // Check for low flowering/fruiting promotion
    if (profile.fruitingPromotion < 0.4) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.fruiting,
        description: 'Kulang sa nutrients para sa fruiting. Magdagdag ng mga prutas na ingredients.',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Saging (Banana)', 'FFJ'),
            relevance: 0.9,
            suggestedAmount: 2.0,
            reason: 'Mataas sa potassium (K) - essential para sa fruit development',
          ),
          IngredientSuggestion(
            ingredient: _createMockIngredient('Papaya', 'FFJ'),
            relevance: 0.8,
            suggestedAmount: 1.5,
            reason: 'Natural enzymes at phosphorus para sa flowering',
          ),
        ],
        priority: 1,
      ));
    }
    
    // Check for low leaf growth
    if (profile.leafGrowth < 0.4) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.leafGrowth,
        description: 'Kulang sa nutrients para sa leaf growth. Magdagdag ng mga dahon na ingredients.',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Malunggay (Moringa)', 'FPJ'),
            relevance: 0.95,
            suggestedAmount: 1.0,
            reason: 'Pinakamataas sa nitrogen (N) - essential para sa leaf development',
          ),
          IngredientSuggestion(
            ingredient: _createMockIngredient('Kangkong', 'FPJ'),
            relevance: 0.8,
            suggestedAmount: 1.5,
            reason: 'Mataas sa chlorophyll at growth hormones',
          ),
        ],
        priority: 1,
      ));
    }
    
    // Check for low NPK levels
    if (profile.nitrogen < 2.0) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.nitrogen,
        description: 'Mababa ang Nitrogen (N). Kailangan para sa green leaves at overall growth.',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Young Leaves', 'FPJ'),
            relevance: 0.9,
            suggestedAmount: 1.0,
            reason: 'Mga batang dahon ay mataas sa nitrogen',
          ),
        ],
        priority: 2,
      ));
    }
    
    if (profile.phosphorus < 1.5) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.phosphorus,
        description: 'Mababa ang Phosphorus (P). Kailangan para sa root development at flowering.',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Root Vegetables', 'FPJ'),
            relevance: 0.8,
            suggestedAmount: 1.5,
            reason: 'Mga ugat ay mataas sa phosphorus',
          ),
        ],
        priority: 2,
      ));
    }
    
    if (profile.potassium < 2.0) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.potassium,
        description: 'Mababa ang Potassium (K). Kailangan para sa fruit quality at disease resistance.',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Banana Peel', 'FFJ'),
            relevance: 0.9,
            suggestedAmount: 2.0,
            reason: 'Balat ng saging ay pinakamataas sa potassium',
          ),
        ],
        priority: 2,
      ));
    }
    
    return recommendations;
  }

  double _calculateScore(NutrientProfile profile) {
    // Calculate score based on nutrient balance and crop target
    double score = 50.0; // Base score
    
    // Add points for good nutrient levels
    if (profile.nitrogen > 1.0) score += 10;
    if (profile.phosphorus > 1.0) score += 10;
    if (profile.potassium > 1.0) score += 10;
    
    // Add points for plant benefits
    if (profile.leafGrowth > 0.3) score += 10;
    if (profile.fruitingPromotion > 0.3) score += 10;
    if (profile.rootDevelopment > 0.3) score += 5;
    
    // Bonus for balanced profile
    final npkBalance = (profile.nitrogen + profile.phosphorus + profile.potassium) / 3;
    if (npkBalance > 2.0) score += 15;
    
    return score.clamp(0.0, 100.0);
  }

  Ingredient _createMockIngredient(String name, String category) {
    return Ingredient(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      category: category,
      description: 'Mock ingredient for demonstration',
      recommendedFor: [widget.cropTarget],
      precautions: ['Use as recommended'],
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: NatureColors.primaryGreen, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nutrient Analysis',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NatureColors.primaryGreen,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error analyzing recipe: $_error',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              )
            else if (_analysis != null)
              _buildAnalysisContent()
            else if (widget.ingredients.isEmpty)
              _buildEmptyState()
            else
              _buildLoadingState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.eco,
            size: 64,
            color: NatureColors.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            '🌱 Magdagdag ng ingredients para makita ang analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: NatureColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Piliin ang mga ingredients na gusto mo gamitin sa recipe mo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: NatureColors.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            '🔍 Ina-analyze ang nutrients...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: NatureColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Salamat sa paghintay, farmer! 🌾',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    final analysis = _analysis!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupportMeters(analysis.totalNutrients),
        const SizedBox(height: 16),
        _buildDilutionAndCoverage(widget.ingredients),
      ],
    );
  }

  Widget _buildSupportMeters(NutrientProfile profile) {
    // Calculate values based on NPK
    // Normalize to 0-1 scale (assuming max of 10 for each nutrient)
    final maxValue = 10.0;
    
    // Plant Growth - based on Nitrogen (N is for leaf growth)
    final plantGrowthValue = (profile.nitrogen / maxValue).clamp(0.0, 1.0);
    
    // Flowering & Fruiting - based on Phosphorus and Potassium (P for flowering, K for fruiting)
    final floweringFruitingValue = ((profile.phosphorus + profile.potassium) / (maxValue * 2)).clamp(0.0, 1.0);
    
    // Root Health - based on Phosphorus (P is for root development)
    final rootHealthValue = (profile.phosphorus / maxValue).clamp(0.0, 1.0);
    
    // Disease Resistance - based on Potassium (K is for disease resistance)
    final diseaseResistanceValue = (profile.potassium / maxValue).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NPK Values Display
        _buildNPKDisplay(profile),
        const SizedBox(height: 16),
        
        _farmerMeterRow('Plant Growth', 'For healthy leaves and stems', plantGrowthValue, Colors.green),
        const SizedBox(height: 8),
        _farmerMeterRow('Flowering & Fruiting', 'For more flowers and fruits', floweringFruitingValue, Colors.orange),
        const SizedBox(height: 8),
        _farmerMeterRow('Root Health', 'For strong roots', rootHealthValue, Colors.brown),
        const SizedBox(height: 8),
        _farmerMeterRow('Disease Resistance', 'For stronger plants', diseaseResistanceValue, Colors.blue),
      ],
    );
  }

  Widget _buildNPKDisplay(NutrientProfile profile) {
    // Calculate max value for percentage calculation (assuming max of 10 for each nutrient)
    const maxValue = 10.0;
    final nPercent = (profile.nitrogen / maxValue).clamp(0.0, 1.0);
    final pPercent = (profile.phosphorus / maxValue).clamp(0.0, 1.0);
    final kPercent = (profile.potassium / maxValue).clamp(0.0, 1.0);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Nutrients (NPK)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nitrogen - Vertical layout
            _buildNPKBar('N', 'Nitrogen', profile.nitrogen, nPercent, Colors.green),
            const SizedBox(height: 12),
            // Phosphorus - Vertical layout
            _buildNPKBar('P', 'Phosphorus', profile.phosphorus, pPercent, Colors.orange),
            const SizedBox(height: 12),
            // Potassium - Vertical layout
            _buildNPKBar('K', 'Potassium', profile.potassium, kPercent, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildNPKBar(String symbol, String name, double value, double percent, Color color) {
    final pct = (percent * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _farmerMeterRow(String title, String description, double value, Color color) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDilutionAndCoverage(List<RecipeIngredient> ingredients) {
    // Get coverage description based on batch size
    String coverageDescription;
    
    if (widget.batchSize <= 1.5) {
      coverageDescription = '5-8 sqm - Small backyard';
    } else if (widget.batchSize <= 3.0) {
      coverageDescription = '10-15 sqm - Medium backyard';
    } else if (widget.batchSize <= 6.0) {
      coverageDescription = '20-30 sqm - Large backyard';
    } else {
      coverageDescription = '30-50 sqm - Small farm';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'How to Use the Recipe',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUsageCard(
            '💧 Dilution Ratio',
            '1:100 (1 part FPJ/FFJ to 100 parts water)',
            'Example: 1 cup of FPJ to 100 cups of water = 1 liter',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '📏 Coverage Area',
            '${widget.batchSize.toStringAsFixed(1)}kg',
            coverageDescription,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '⏰ Application',
            'Spray in the morning (6-8 AM) or afternoon (4-6 PM), 2-3 times per week',
            'Best time: morning before it gets hot, afternoon after the heat',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, String description, String tip, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }










}
