import 'package:agrimix/models/ingredient.dart';
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/nutrient_profile.dart';
import '../../services/analytics_service.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';

class RecipeAnalyticsWidget extends StatefulWidget {
  final List<RecipeIngredient> ingredients;
  final String cropTarget;
  final Function(List<RecipeIngredient>)? onIngredientsUpdated;
  final double? batchSizeKg;

  const RecipeAnalyticsWidget({
    super.key,
    required this.ingredients,
    required this.cropTarget,
    this.onIngredientsUpdated,
    this.batchSizeKg,
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
      final analytics = context.read<AnalyticsService>();
      final analysis = await analytics.analyzeRecipe(widget.ingredients, widget.cropTarget);
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

  // Mock/helper methods removed in favor of AnalyticsService

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
                        '🌾 Nutrient Analysis for Recipe',
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
            'Choose the ingredients you want to use in your recipe',
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
            '🔍 Analyzing nutrients...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: NatureColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for waiting, farmer! 🌾',
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
        // Removed fit/assessment badge per request
        _buildNpkBreakdown(analysis.totalNutrients),
        const SizedBox(height: 12),
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
    // Derive functional support (Growth, Flowering/Fruiting, Root, Resistance)
    // directly from NPK so it's relatable to users
    double n = profile.nitrogen.abs();
    double p = profile.phosphorus.abs();
    double k = profile.potassium.abs();
    final total = (n + p + k);

    double safeDiv(double num, double den) => den == 0 ? 0.0 : (num / den).clamp(0.0, 1.0);

    final growth = safeDiv(n, total);                 // Leaf/stem growth ~ Nitrogen
    final flowering = safeDiv(0.7 * k + 0.3 * p, total); // Flowering/Fruiting ~ mostly K, some P
    final root = safeDiv(p, total);                   // Root development ~ Phosphorus
    final resistance = safeDiv(k, total);             // Disease/stress resistance ~ Potassium

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
        _farmerMeterRow('🌱 Plant Growth', 'Supports healthy leaves and stems', growth, Colors.green),
        const SizedBox(height: 8),
        _farmerMeterRow('🌸 Flowering & Fruiting', 'Boosts flowers and fruit set', flowering, Colors.orange),
        const SizedBox(height: 8),
        _farmerMeterRow('🌿 Root Health', 'Strengthens root development', root, Colors.brown),
        const SizedBox(height: 8),
        _farmerMeterRow('🛡️ Disease Resistance', 'Helps plants resist diseases', resistance, Colors.blue),
      ],
    );
  }

  Widget _buildNpkBreakdown(NutrientProfile profile) {
    final n = profile.nitrogen.abs();
    final p = profile.phosphorus.abs();
    final k = profile.potassium.abs();
    final total = (n + p + k);

    double pct(double v) => total > 0 ? (v / total).clamp(0.0, 1.0) : 0.0;

    Widget bar(String label, double value, Color color) {
      final percent = (pct(value) * 100).round();
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct(value),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total > 0 ? '$percent%' : '0%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.purple.shade700, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'NPK Breakdown (relative share)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          bar('N', n, Colors.teal),
          bar('P', p, Colors.amber),
          bar('K', k, Colors.indigo),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No NPK data for the selected ingredients.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
            ),
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
      status = 'Katamtaman';
      statusColor = Colors.orange;
    } else {
      status = 'Needs work';
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


  // Suggested mix section removed per request

  Widget _buildDilutionAndCoverage(List<RecipeIngredient> ingredients) {
    // Coverage must match Step 1 notes exactly
    // Mapping: 1.5kg → 5–8 sqm, 3kg → 10–15 sqm, 6kg → 20–30 sqm, 9kg → 30–50 sqm
    final selectedBatchKg = widget.batchSizeKg;
    double inferredKg;
    if (selectedBatchKg != null) {
      inferredKg = selectedBatchKg;
    } else {
      // Fallback: infer from total kg and snap to nearest supported batch size
      final totalKg = ingredients.fold<double>(0.0, (sum, ri) => sum + (ri.unit.toLowerCase().contains('kg') ? ri.amount : 0.0));
      final options = [1.5, 3.0, 6.0, 9.0];
      options.sort((a, b) => (a - totalKg).abs().compareTo((b - totalKg).abs()));
      inferredKg = options.first;
    }

    String coverageFor(double kg) {
      if ((kg - 1.5).abs() < 0.76) return '5–8 sqm';
      if ((kg - 3.0).abs() < 0.76) return '10–15 sqm';
      if ((kg - 6.0).abs() < 1.6) return '20–30 sqm';
      return '30–50 sqm';
    }
    final coverageLabel = coverageFor(inferredKg);

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
                  'How to use the recipe',
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
            'Example: 1 cup FPJ to 100 cups water ≈ 1 liter',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '📏 Coverage Area',
            '~$coverageLabel',
            'Based on selected batch: ${inferredKg.toStringAsFixed(1)} kg',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildUsageCard(
            '⏰ Application',
            'Spray in the morning (6–8 AM) or late afternoon (4–6 PM), 2–3x a week',
            'Best time: early morning before heat, or late afternoon after heat',
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

  // Tips section removed per request













}
