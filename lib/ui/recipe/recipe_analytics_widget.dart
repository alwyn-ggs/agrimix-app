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
    required this.batchSize,
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
    int processedIngredients = 0;

    for (final recipeIngredient in widget.ingredients) {
      try {
        final ingredient = await ingredientsRepo.getIngredient(recipeIngredient.ingredientId);
        if (ingredient?.nutrientProfile != null) {
          // Scale the nutrient profile by the amount used in the recipe
          final scaledProfile = ingredient!.nutrientProfile! * recipeIngredient.amount;
          totalProfile = totalProfile + scaledProfile;
          processedIngredients++;
          
          // Debug: Print individual ingredient contributions
          print('Ingredient: ${ingredient.name} (${recipeIngredient.amount}${recipeIngredient.unit})');
          print('  N: ${scaledProfile.nitrogen.toStringAsFixed(2)}, P: ${scaledProfile.phosphorus.toStringAsFixed(2)}, K: ${scaledProfile.potassium.toStringAsFixed(2)}');
        }
      } catch (e) {
        print('Error processing ingredient ${recipeIngredient.ingredientId}: $e');
        continue;
      }
    }

    // Debug: Print final totals
    print('Total NPK from $processedIngredients ingredients:');
    print('  N: ${totalProfile.nitrogen.toStringAsFixed(2)}, P: ${totalProfile.phosphorus.toStringAsFixed(2)}, K: ${totalProfile.potassium.toStringAsFixed(2)}');
    
    return totalProfile;
  }

  List<NutrientRecommendation> _generateRecommendations(NutrientProfile profile) {
    final recommendations = <NutrientRecommendation>[];
    
    // Check for low flowering/fruiting promotion
    if (profile.fruitingPromotion < 0.4) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.fruiting,
        description: 'Low nutrients for fruiting. Add more fruit ingredients.',
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
            reason: 'Natural enzymes and phosphorus for flowering',
          ),
        ],
        priority: 1,
      ));
    }
    
    // Check for low leaf growth
    if (profile.leafGrowth < 0.4) {
      recommendations.add(NutrientRecommendation(
        type: NutrientDeficiencyType.leafGrowth,
        description: 'Low nutrients for leaf growth. Add more leafy ingredients.',
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
        description: 'Low Nitrogen (N). Needed for green leaves and overall growth.',
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
        description: 'Low Phosphorus (P). Needed for root development and flowering.',
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
        description: 'Low Potassium (K). Needed for fruit quality and disease resistance.',
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
                        '🌾 Recipe Nutrient Analysis',
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
            '🌱 Add ingredients to see the analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: NatureColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select ingredients you want to use in your recipe',
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

  Widget _buildFitBadge(RecipeNutrientAnalysis analysis) {
    // Farmer-friendly assessment based on crop target and nutrient balance
    final profile = analysis.totalNutrients;
    final crop = analysis.cropTarget.toLowerCase();
    final isFloweringCrop = crop.contains('tomato') || crop.contains('ampalaya') || crop.contains('flower') || 
                           crop.contains('okra') || crop.contains('sitaw') || crop.contains('talong');
    final growthScore = profile.leafGrowth;
    final flowerScore = profile.fruitingPromotion;
    final rootScore = profile.rootDevelopment;

    String title;
    String description;
    Color color;
    IconData icon;
    
    if (isFloweringCrop) {
      if (flowerScore >= 0.6 && growthScore >= 0.4) {
        title = '✅ Great Recipe!';
        description = 'Perfect para sa mga halaman na nagbubunga';
        color = Colors.green;
        icon = Icons.thumb_up;
      } else if (flowerScore >= 0.4) {
        title = '⚠️ Kailangan pa ng konti';
        description = 'Dagdag ng ingredients para sa mas maraming bunga';
        color = Colors.orange;
        icon = Icons.trending_up;
      } else {
        title = '❌ Kailangan ng adjustment';
        description = 'Dagdag ng flowering ingredients';
        color = Colors.red;
        icon = Icons.warning;
      }
    } else {
      if (growthScore >= 0.6 && rootScore >= 0.4) {
        title = '✅ Great Recipe!';
        description = 'Perfect para sa malusog na paglaki ng halaman';
        color = Colors.green;
        icon = Icons.thumb_up;
      } else if (growthScore >= 0.4) {
        title = '⚠️ Kailangan pa ng konti';
        description = 'Dagdag ng ingredients para sa mas malusog na paglaki';
        color = Colors.orange;
        icon = Icons.trending_up;
      } else {
        title = '❌ Kailangan ng adjustment';
        description = 'Dagdag ng growth ingredients';
        color = Colors.red;
        icon = Icons.warning;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportMeters(NutrientProfile profile) {
    // Farmer-friendly nutrient display with simple terms
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NPK Values Display
        _buildNPKDisplay(profile),
        const SizedBox(height: 16),
        
        _farmerMeterRow('🌱 Plant Growth', 'For healthy leaves and stems', _calculatePlantGrowth(profile), Colors.green),
        const SizedBox(height: 8),
        _farmerMeterRow('🌸 Flowering & Fruiting', 'For more flowers and fruits', _calculateFloweringFruiting(profile), Colors.orange),
        const SizedBox(height: 8),
        _farmerMeterRow('🌿 Root Health', 'For strong root system', _calculateRootHealth(profile), Colors.brown),
        const SizedBox(height: 8),
        _farmerMeterRow('🛡️ Disease Resistance', 'For stronger plant immunity', _calculateDiseaseResistance(profile), Colors.blue),
      ],
    );
  }

  Widget _buildNPKDisplay(NutrientProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
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
          _buildNPKRow('N', profile.nitrogen, Colors.green),
        const SizedBox(height: 12),
          _buildNPKRow('P', profile.phosphorus, Colors.orange),
          const SizedBox(height: 12),
          _buildNPKRow('K', profile.potassium, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildNPKRow(String symbol, double value, Color color) {
    // Calculate percentage (assuming max ideal value of 5.0 for each nutrient)
    final percentage = (value / 5.0).clamp(0.0, 1.0);
    final percentText = '${(percentage * 100).round()}%';
    
    return Row(
      children: [
        // Symbol
        SizedBox(
          width: 20,
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Progress loading line
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Percentage
        SizedBox(
          width: 40,
          child: Text(
            percentText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientCard(String symbol, String name, double value, Color color, String purpose) {
    // Calculate percentage (assuming max ideal value of 5.0 for each nutrient)
    final percentage = (value / 5.0).clamp(0.0, 1.0);
    final percentText = '${(percentage * 100).round()}%';
    
    // Determine quality level
    String quality;
    Color qualityColor;
    if (percentage >= 0.8) {
      quality = 'Excellent';
      qualityColor = Colors.green;
    } else if (percentage >= 0.6) {
      quality = 'Good';
      qualityColor = Colors.lightGreen;
    } else if (percentage >= 0.4) {
      quality = 'Fair';
      qualityColor = Colors.orange;
    } else {
      quality = 'Low';
      qualityColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with symbol and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: qualityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percentText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: qualityColor,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
          
          // Value display
          Text(
            '${value.toStringAsFixed(1)} mg/L',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        const SizedBox(height: 8),
          
          // Horizontal percentage bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                quality,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: qualityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Purpose
          Text(
            purpose,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Calculate plant growth based on Nitrogen levels
  double _calculatePlantGrowth(NutrientProfile profile) {
    // Plant growth is primarily driven by Nitrogen (N)
    // Also influenced by overall nutrient balance
    final nitrogenScore = (profile.nitrogen / 5.0).clamp(0.0, 1.0); // Max 5.0 mg/L
    final balanceBonus = _calculateNutrientBalance(profile) * 0.2; // 20% bonus for balance
    final leafGrowthBonus = profile.leafGrowth * 0.3; // 30% from ingredient leaf growth properties
    
    return (nitrogenScore * 0.5 + balanceBonus + leafGrowthBonus).clamp(0.0, 1.0);
  }

  // Calculate flowering & fruiting based on Phosphorus and Potassium
  double _calculateFloweringFruiting(NutrientProfile profile) {
    // Flowering needs Phosphorus (P), Fruiting needs Potassium (K)
    final phosphorusScore = (profile.phosphorus / 3.0).clamp(0.0, 1.0); // Max 3.0 mg/L
    final potassiumScore = (profile.potassium / 5.0).clamp(0.0, 1.0); // Max 5.0 mg/L
    final fruitingBonus = profile.fruitingPromotion * 0.3; // 30% from ingredient properties
    
    return ((phosphorusScore + potassiumScore) / 2.0 * 0.7 + fruitingBonus).clamp(0.0, 1.0);
  }

  // Calculate root health based on Phosphorus and secondary nutrients
  double _calculateRootHealth(NutrientProfile profile) {
    // Root development needs Phosphorus (P) and Calcium (Ca)
    final phosphorusScore = (profile.phosphorus / 3.0).clamp(0.0, 1.0);
    final calciumScore = (profile.calcium / 2.0).clamp(0.0, 1.0); // Max 2.0 mg/L
    final rootDevBonus = profile.rootDevelopment * 0.4; // 40% from ingredient properties
    
    return ((phosphorusScore + calciumScore) / 2.0 * 0.6 + rootDevBonus).clamp(0.0, 1.0);
  }

  // Calculate disease resistance based on Potassium and micronutrients
  double _calculateDiseaseResistance(NutrientProfile profile) {
    // Disease resistance comes from Potassium (K) and balanced nutrition
    final potassiumScore = (profile.potassium / 5.0).clamp(0.0, 1.0);
    final micronutrientScore = ((profile.iron + profile.zinc + profile.manganese) / 3.0).clamp(0.0, 1.0);
    final resistanceBonus = profile.diseaseResistance * 0.3; // 30% from ingredient properties
    
    return ((potassiumScore + micronutrientScore) / 2.0 * 0.7 + resistanceBonus).clamp(0.0, 1.0);
  }

  // Calculate overall nutrient balance
  double _calculateNutrientBalance(NutrientProfile profile) {
    // Ideal NPK ratio is roughly 3:1:2 (N:P:K)
    final n = profile.nitrogen;
    final p = profile.phosphorus;
    final k = profile.potassium;
    
    if (n == 0 && p == 0 && k == 0) return 0.0;
    
    // Calculate how close we are to ideal ratios
    final total = n + p + k;
    final nRatio = n / total;
    final pRatio = p / total;
    final kRatio = k / total;
    
    // Ideal ratios (normalized): N=0.5, P=0.17, K=0.33
    final nDiff = (nRatio - 0.5).abs();
    final pDiff = (pRatio - 0.17).abs();
    final kDiff = (kRatio - 0.33).abs();
    
    final balance = 1.0 - ((nDiff + pDiff + kDiff) / 3.0);
    return balance.clamp(0.0, 1.0);
  }

  Widget _buildPlantApplications(NutrientProfile profile) {
    final applications = <String>[];
    
    // Use calculated values based on NPK
    final plantGrowth = _calculatePlantGrowth(profile);
    final floweringFruiting = _calculateFloweringFruiting(profile);
    final rootHealth = _calculateRootHealth(profile);
    final diseaseResistance = _calculateDiseaseResistance(profile);
    
    // Determine best applications based on calculated scores
    if (plantGrowth > 0.6) {
      applications.add('✅ Excellent for Vegetative Growth');
    } else if (plantGrowth > 0.4) {
      applications.add('✅ Good for Vegetative Growth');
    }
    
    if (floweringFruiting > 0.6) {
      applications.add('✅ Excellent for Flowering & Fruiting');
    } else if (floweringFruiting > 0.4) {
      applications.add('✅ Good for Flowering & Fruiting');
    }
    
    if (rootHealth > 0.6) {
      applications.add('✅ Excellent for Root Development');
    } else if (rootHealth > 0.4) {
      applications.add('✅ Good for Root Development');
    }
    
    if (diseaseResistance > 0.6) {
      applications.add('✅ Excellent for Disease Resistance');
    } else if (diseaseResistance > 0.4) {
      applications.add('✅ Good for Disease Resistance');
    }
    
    // NPK-specific recommendations
    if (profile.nitrogen > 3.0) {
      applications.add('✅ High Nitrogen - Perfect for leafy vegetables');
    }
    if (profile.potassium > 3.0) {
      applications.add('✅ High Potassium - Perfect for fruiting plants');
    }
    if (profile.phosphorus > 2.0) {
      applications.add('✅ High Phosphorus - Perfect for flowering');
    }
    
    if (applications.isEmpty) {
      applications.add('⚠️ Add more ingredients for better results');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plant Applications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...applications.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              app,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _farmerMeterRow(String title, String description, double value, Color color) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    String status;
    Color statusColor;
    
    if (pct >= 70) {
      status = 'Good';
      statusColor = Colors.green;
    } else if (pct >= 40) {
      status = 'Fair';
      statusColor = Colors.orange;
    } else {
      status = 'Low';
      statusColor = Colors.red;
    }
    
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSuggestedMix(List<RecipeIngredient> ingredients) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '🌱 Suggested Recipe Mix',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ingredients.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No ingredients selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...ingredients.map((ri) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ri.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ri.amount.toStringAsFixed(1)} ${ri.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildDilutionAndCoverage(List<RecipeIngredient> ingredients) {
    // Use the selected batch size from step 1 to determine coverage
    String coverageRange;
    String areaDescription;
    
    switch (widget.batchSize) {
      case 1.5:
        coverageRange = '5-8 sqm';
        areaDescription = 'Small backyard';
        break;
      case 3.0:
        coverageRange = '10-15 sqm';
        areaDescription = 'Medium backyard';
        break;
      case 6.0:
        coverageRange = '20-30 sqm';
        areaDescription = 'Large backyard';
        break;
      case 9.0:
        coverageRange = '30-50 sqm';
        areaDescription = 'Small farm';
        break;
      default:
        coverageRange = '10-15 sqm';
        areaDescription = 'Medium backyard';
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
            'Example: 1 cup FPJ to 100 cups water = 1 liter solution',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '📏 Coverage Area',
            'Approximately $coverageRange',
            '${widget.batchSize}kg batch - $areaDescription',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '⏰ Application',
            'Spray in the morning (6-8 AM) or afternoon (4-6 PM), 2-3 times per week',
            'Best time: morning before heat, afternoon after heat subsides',
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
