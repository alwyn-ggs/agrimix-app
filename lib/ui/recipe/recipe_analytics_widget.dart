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
  final Function(List<RecipeIngredient>)? onIngredientsUpdated;

  const RecipeAnalyticsWidget({
    super.key,
    required this.ingredients,
    required this.cropTarget,
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
                        '🌾 Nutrient Analysis para sa Recipe',
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
        _buildFitBadge(analysis),
        const SizedBox(height: 12),
        _buildSupportMeters(analysis.totalNutrients),
        const SizedBox(height: 16),
        _buildSuggestedMix(widget.ingredients),
        const SizedBox(height: 16),
        _buildDilutionAndCoverage(widget.ingredients),
        const SizedBox(height: 12),
        _buildQuickTips(analysis),
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
        title = '✅ Magandang Recipe!';
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
        title = '✅ Magandang Recipe!';
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
        Row(
          children: [
            const Icon(Icons.eco, color: NatureColors.primaryGreen, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Nutrient Analysis',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // NPK Values Display
        _buildNPKDisplay(profile),
        const SizedBox(height: 16),
        
        // Plant Application Recommendations
        _buildPlantApplications(profile),
        const SizedBox(height: 16),
        
        _farmerMeterRow('🌱 Plant Growth', 'Para sa malusog na dahon at tangkay', profile.leafGrowth, Colors.green),
        const SizedBox(height: 8),
        _farmerMeterRow('🌸 Flowering & Fruiting', 'Para sa mas maraming bulaklak at bunga', profile.fruitingPromotion, Colors.orange),
        const SizedBox(height: 8),
        _farmerMeterRow('🌿 Root Health', 'Para sa malakas na ugat', profile.rootDevelopment, Colors.brown),
        const SizedBox(height: 8),
        _farmerMeterRow('🛡️ Disease Resistance', 'Para sa mas malakas na halaman', profile.diseaseResistance, Colors.blue),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildNutrientCard('N', 'Nitrogen', profile.nitrogen, Colors.green, 'Leaf Growth')),
              const SizedBox(width: 8),
              Expanded(child: _buildNutrientCard('P', 'Phosphorus', profile.phosphorus, Colors.orange, 'Root & Flower')),
              const SizedBox(width: 8),
              Expanded(child: _buildNutrientCard('K', 'Potassium', profile.potassium, Colors.purple, 'Fruit Quality')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String symbol, String name, double value, Color color, String purpose) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            purpose,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantApplications(NutrientProfile profile) {
    final applications = <String>[];
    
    // Determine best applications based on nutrient profile
    if (profile.leafGrowth > 0.4) {
      applications.add('✅ Maganda para sa Vegetative Growth');
    }
    if (profile.fruitingPromotion > 0.4) {
      applications.add('✅ Maganda para sa Flowering & Fruiting');
    }
    if (profile.rootDevelopment > 0.3) {
      applications.add('✅ Maganda para sa Root Development');
    }
    if (profile.nitrogen > 2.0) {
      applications.add('✅ Mataas sa Nitrogen - Perfect para sa leafy vegetables');
    }
    if (profile.potassium > 2.0) {
      applications.add('✅ Mataas sa Potassium - Perfect para sa fruiting plants');
    }
    if (profile.phosphorus > 1.5) {
      applications.add('✅ Mataas sa Phosphorus - Perfect para sa flowering');
    }
    
    if (applications.isEmpty) {
      applications.add('⚠️ Kailangan pa ng more ingredients para sa better results');
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
      status = 'Maganda';
      statusColor = Colors.green;
    } else if (pct >= 40) {
      status = 'Katamtaman';
      statusColor = Colors.orange;
    } else {
      status = 'Kailangan pa';
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
                  '🌱 Suggested Mix para sa Recipe',
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
                    'Walang ingredients na napili',
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
    // Farmer-friendly dilution and coverage calculation
    final totalKg = ingredients.fold<double>(0.0, (sum, ri) => sum + (ri.unit.toLowerCase().contains('kg') ? ri.amount : 0.0));
    final coverageSqm = (totalKg * 10).clamp(5, 200).round();
    final plants = (coverageSqm * 3 / 2).round();

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
                  'Paano gamitin ang Recipe',
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
            '1:100 (1 parte ng FPJ/FFJ sa 100 parte ng tubig)',
            'Halimbawa: 1 baso ng FPJ sa 100 baso ng tubig = 1 liter',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '📏 Coverage Area',
            '~$coverageSqm square meters o ~$plants na halaman',
            'Saklaw ng recipe mo para sa buong garden',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '⏰ Application',
            'I-spray sa umaga (6-8 AM) o hapon (4-6 PM), 2-3 beses sa isang linggo',
            'Pinakamagandang oras: umaga bago mag-init, hapon pagkatapos ng init',
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

  Widget _buildQuickTips(RecipeNutrientAnalysis analysis) {
    final tips = <Map<String, String>>[];
    final profile = analysis.totalNutrients;
    
    if (profile.fruitingPromotion < 0.6) {
      tips.add({
        'icon': '🌸',
        'title': 'Para sa mas maraming bunga',
        'tip': 'Dagdag ng saging (2-3 piraso), papaya (1/2 piraso)'
      });
    }
    if (profile.leafGrowth < 0.6) {
      tips.add({
        'icon': '🌱',
        'title': 'Para sa malusog na dahon',
        'tip': 'Dagdag ng malunggay (1-2 cups), kangkong (1 cup)'
      });
    }
    if (profile.rootDevelopment < 0.6) {
      tips.add({
        'icon': '🌿',
        'title': 'Para sa malakas na ugat',
        'tip': 'Dagdag ng kamote tops (1 cup), luya (1-2 piraso)'
      });
    }
    if (profile.diseaseResistance < 0.6) {
      tips.add({
        'icon': '🛡️',
        'title': 'Para sa mas malakas na halaman',
        'tip': 'Dagdag ng luya (2-3 piraso), bawang (3-5 piraso)'
      });
    }
    
    if (tips.isEmpty) {
      tips.add({
        'icon': '✅',
        'title': 'Magandang recipe!',
        'tip': 'Perfect na para sa crop mo! Good job, farmer! 🌾'
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mga Tips para sa Recipe',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.take(3).map((tip) => _buildTipCard(tip)),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, String> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip['icon']!,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['tip']!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }













}
