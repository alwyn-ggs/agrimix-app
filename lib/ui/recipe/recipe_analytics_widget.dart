import 'package:agrimix/models/ingredient.dart';
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/nutrient_profile.dart';
import '../../services/analytics_service.dart';
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
      // This would normally use the AnalyticsService, but for now we'll create a mock analysis
      // In a real implementation, you'd inject the service and call it here
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final analysis = _createMockAnalysis();
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

  // Mock analysis for demonstration - replace with real AnalyticsService call
  RecipeNutrientAnalysis _createMockAnalysis() {
    final totalNutrients = _calculateTotalNutrients();
    final recommendations = _generateMockRecommendations();
    final score = _calculateMockScore(totalNutrients);
    
    return RecipeNutrientAnalysis(
      totalNutrients: totalNutrients,
      recommendations: recommendations,
      overallScore: score,
      cropTarget: widget.cropTarget,
    );
  }

  NutrientProfile _calculateTotalNutrients() {
    // Mock calculation - in real implementation, this would use AnalyticsService
    return const NutrientProfile(
      nitrogen: 2.5,
      phosphorus: 1.8,
      potassium: 3.2,
      calcium: 1.5,
      magnesium: 1.0,
      floweringPromotion: 0.6,
      fruitingPromotion: 0.7,
      rootDevelopment: 0.5,
      leafGrowth: 0.6,
      diseaseResistance: 0.5,
      pestResistance: 0.4,
    );
  }

  List<NutrientRecommendation> _generateMockRecommendations() {
    // Mock recommendations based on the tomato example
    return [
      NutrientRecommendation(
        type: NutrientDeficiencyType.flowering,
        description: 'Low flowering promotion - add ingredients that promote blooming',
        suggestedIngredients: [
          IngredientSuggestion(
            ingredient: _createMockIngredient('Sampaguita Flowers', 'Flower'),
            relevance: 0.9,
            suggestedAmount: 1.5,
            reason: 'High flowering promotion (90%)',
          ),
          IngredientSuggestion(
            ingredient: _createMockIngredient('Crab Shells', 'Animal'),
            relevance: 0.8,
            suggestedAmount: 2.0,
            reason: 'Rich in phosphorus (2.8) and flowering promotion (80%)',
          ),
        ],
        priority: 3,
      ),
    ];
  }

  double _calculateMockScore(NutrientProfile profile) {
    // Mock score calculation
    return 75.0;
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
            Row(
              children: [
                const Icon(Icons.analytics, color: NatureColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Recipe Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NatureColors.primaryGreen,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
          Icon(
            Icons.science,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Add ingredients to see nutrient analysis',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing recipe nutrients...'),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    final analysis = _analysis!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Score
        _buildOverallScore(analysis.overallScore),
        const SizedBox(height: 16),
        
        // Nutrient Breakdown
        _buildNutrientBreakdown(analysis.totalNutrients),
        const SizedBox(height: 16),
        
        // Recommendations
        if (analysis.recommendations.isNotEmpty)
          _buildRecommendations(analysis.recommendations),
      ],
    );
  }

  Widget _buildOverallScore(double score) {
    Color scoreColor;
    String scoreText;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreText = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreText = 'Good';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Needs Improvement';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withAlpha((0.1 * 255).round())),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, color: scoreColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Recipe Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$scoreText (${score.toStringAsFixed(0)}/100)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBreakdown(NutrientProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrient Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // NPK Values
        _buildNutrientRow('NPK', 'N:${profile.nitrogen.toStringAsFixed(1)} P:${profile.phosphorus.toStringAsFixed(1)} K:${profile.potassium.toStringAsFixed(1)}', Colors.blue),
        
        // Plant Benefits
        _buildNutrientRow('Flowering', '${(profile.floweringPromotion * 100).toStringAsFixed(0)}%', Colors.pink),
        _buildNutrientRow('Fruiting', '${(profile.fruitingPromotion * 100).toStringAsFixed(0)}%', Colors.orange),
        _buildNutrientRow('Root Growth', '${(profile.rootDevelopment * 100).toStringAsFixed(0)}%', Colors.brown),
        _buildNutrientRow('Leaf Growth', '${(profile.leafGrowth * 100).toStringAsFixed(0)}%', Colors.green),
        _buildNutrientRow('Disease Resistance', '${(profile.diseaseResistance * 100).toStringAsFixed(0)}%', Colors.red),
      ],
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<NutrientRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ...recommendations.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildRecommendationCard(NutrientRecommendation recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRecommendationIcon(recommendation.type),
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRecommendationTitle(recommendation.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityText(recommendation.priority),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            
            // Suggested ingredients
            Text(
              'Suggested Ingredients:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ...recommendation.suggestedIngredients.map((suggestion) => 
              _buildIngredientSuggestion(suggestion)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSuggestion(IngredientSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.ingredient.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  suggestion.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${suggestion.suggestedAmount.toStringAsFixed(1)}kg',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color:NatureColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: NatureColors.primaryGreen),
            onPressed: () => _addIngredientToRecipe(suggestion),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _addIngredientToRecipe(IngredientSuggestion suggestion) {
    final newIngredient = RecipeIngredient(
      ingredientId: suggestion.ingredient.id,
      name: suggestion.ingredient.name,
      amount: suggestion.suggestedAmount,
      unit: 'kg',
    );
    
    final updatedIngredients = List<RecipeIngredient>.from(widget.ingredients);
    updatedIngredients.add(newIngredient);
    
    widget.onIngredientsUpdated?.call(updatedIngredients);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${suggestion.ingredient.name} to recipe'),
        backgroundColor:NatureColors.primaryGreen,
      ),
    );
  }

  IconData _getRecommendationIcon(NutrientDeficiencyType type) {
    switch (type) {
      case NutrientDeficiencyType.flowering:
        return Icons.local_florist;
      case NutrientDeficiencyType.fruiting:
        return Icons.eco;
      case NutrientDeficiencyType.rootDevelopment:
        return Icons.park;
      case NutrientDeficiencyType.leafGrowth:
        return Icons.forest;
      case NutrientDeficiencyType.diseaseResistance:
        return Icons.health_and_safety;
      case NutrientDeficiencyType.pestResistance:
        return Icons.bug_report;
      default:
        return Icons.science;
    }
  }

  String _getRecommendationTitle(NutrientDeficiencyType type) {
    switch (type) {
      case NutrientDeficiencyType.flowering:
        return 'Improve Flowering';
      case NutrientDeficiencyType.fruiting:
        return 'Improve Fruiting';
      case NutrientDeficiencyType.rootDevelopment:
        return 'Improve Root Development';
      case NutrientDeficiencyType.leafGrowth:
        return 'Improve Leaf Growth';
      case NutrientDeficiencyType.diseaseResistance:
        return 'Improve Disease Resistance';
      case NutrientDeficiencyType.pestResistance:
        return 'Improve Pest Resistance';
      default:
        return 'Nutrient Deficiency';
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'HIGH';
      case 2:
        return 'MEDIUM';
      case 3:
        return 'LOW';
      default:
        return 'INFO';
    }
  }
}
