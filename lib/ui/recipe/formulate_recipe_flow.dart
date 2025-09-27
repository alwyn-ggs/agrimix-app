import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/recipe_provider.dart';
import '../../repositories/recipes_repo.dart';
import '../../repositories/fermentation_repo.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/fermentation_log.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../services/fermentation_guide_service.dart';
import '../../services/notification_service.dart';
import 'fermentation_guide_screen.dart';
import 'recipe_analytics_widget.dart';

class FormulateRecipeFlow extends StatefulWidget {
  const FormulateRecipeFlow({super.key});

  @override
  State<FormulateRecipeFlow> createState() => _FormulateRecipeFlowState();
}

class _FormulateRecipeFlowState extends State<FormulateRecipeFlow> {
  int _step = 0;
  RecipeMethod _method = RecipeMethod.ffj;
  Set<String> _selectedIds = <String>{};
  final TextEditingController _cropCtrl = TextEditingController();
  final TextEditingController _newIngCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _saving = false;
  final Map<String, Ingredient> _localAdded = <String, Ingredient>{};
  // Shared cache for ingredient image URLs across steps
  final Map<String, String?> _imageUrlCache = <String, String?>{};
  final List<String> _cropOptions = const [
    'Ampalaya',
    'Eggplant',
    'Tomatoes',
    'Okra',
    'Upo (gourd)',
    'Squash',
    'Pole sitaw',
  ];
  String? _selectedCrop;
  List<String> get _filteredCropTargets {
    // All crops are now available for both FFJ and FPJ methods
    return _cropOptions;
  }
  
  // Batch size options with coverage area information (adjusted for local gardening)
  final List<double> _batchSizes = [1.5, 3.0, 6.0, 9.0];
  final List<String> _batchSizeLabels = [
    'Small (1.5kg)',
    'Medium (3kg)', 
    'Large (6kg)',
    'Extra Large (9kg)'
  ];
  double _selectedBatchSize = 3.0;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _newIngCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulate Recipe', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStepContent(context),
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomBar(context)),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    switch (_step) {
      case 0:
        return Padding(
          key: const ValueKey('step0'),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [
                    _method == RecipeMethod.ffj,
                    _method == RecipeMethod.fpj,
                  ],
                  onPressed: (i) => setState(() {
                    _method = i == 0 ? RecipeMethod.ffj : RecipeMethod.fpj;
                    // No need to reset selected crop since all crops are available for both methods
                  }),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('FFJ', style: TextStyle(color: Colors.black))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('FPJ', style: TextStyle(color: Colors.black))),
                  ],
                ),
                const SizedBox(height: 16),
                // Recipe name input
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Recipe name*',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., FFJ for Tomatoes - Banana Blend',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  value: _selectedBatchSize,
                  onChanged: (value) => setState(() => _selectedBatchSize = value!),
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Batch Size',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(_batchSizes.length, (index) {
                    return DropdownMenuItem<double>(
                      value: _batchSizes[index],
                      child: Text(_batchSizeLabels[index], style: const TextStyle(color: Colors.black)),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coverage:\n'
                          '• Small (1.5kg) - 5-8 sqm - Small backyard\n'
                          '• Medium (3kg) - 10-15 sqm - Medium backyard\n'
                          '• Large (6kg) - 20-30 sqm - Large backyard\n'
                          '• Extra Large (9kg) - 30-50 sqm - Small farm\n',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Crop target dropdown
                DropdownButtonFormField<String>(
                  value: _filteredCropTargets.contains(_selectedCrop) ? _selectedCrop : null,
                  onChanged: (value) => setState(() => _selectedCrop = value),
                  decoration: const InputDecoration(
                    labelText: 'Crop target*',
                    border: OutlineInputBorder(),
                  ),
                  items: _filteredCropTargets
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const _SafetyNote(),
              ],
            ),
          ),
        );
      case 1:
        final all = recipeProvider.allIngredients;
        final selectedIngredients = _resolveSelectedIngredients(context);
        final recipeIngredients = selectedIngredients.map((ingredient) => 
          RecipeIngredient(
            ingredientId: ingredient.id,
            name: ingredient.name,
            amount: 1.0, // Default amount for analytics
            unit: 'kg',
          )
        ).toList();
        
        return Padding(
          key: const ValueKey('step1'),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _IngredientSelectionWidget(
                  allIngredients: all,
                  method: _method,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (selectedIds) => setState(() => _selectedIds = selectedIds),
                ),
                const SizedBox(height: 16),
                
                // Analytics Widget
                if (selectedIngredients.isNotEmpty)
                  RecipeAnalyticsWidget(
                    ingredients: recipeIngredients,
                    cropTarget: _selectedCrop ?? 'General',
                    onIngredientsUpdated: (updatedIngredients) {
                      // Update the selected ingredients based on analytics suggestions
                      final newSelectedIds = updatedIngredients.map((ri) => ri.ingredientId).toSet();
                      setState(() => _selectedIds = newSelectedIds);
                    },
                  ),
                
                const SizedBox(height: 100), // padding for bottom bar
              ],
            ),
          ),
        );
      case 2:
        final selectedIngredients = _resolveSelectedIngredients(context);
        final recipeIngredients = selectedIngredients.map((ingredient) => 
          RecipeIngredient(
            ingredientId: ingredient.id,
            name: ingredient.name,
            amount: 1.0, // Default amount for analytics
            unit: 'kg',
          )
        ).toList();
        
        return Padding(
          key: const ValueKey('step2'),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _RatiosAndSteps(
                  method: _method,
                  selected: selectedIngredients,
                  batchSize: _selectedBatchSize,
                ),
                const SizedBox(height: 16),
                
                // Final Analytics Review
                if (selectedIngredients.isNotEmpty)
                  RecipeAnalyticsWidget(
                    ingredients: recipeIngredients,
                    cropTarget: _selectedCrop ?? 'General',
                    onIngredientsUpdated: (updatedIngredients) {
                      // Update the selected ingredients based on analytics suggestions
                      final newSelectedIds = updatedIngredients.map((ri) => ri.ingredientId).toSet();
                      setState(() => _selectedIds = newSelectedIds);
                    },
                  ),
                
                const SizedBox(height: 100), // padding for bottom bar
              ],
            ),
          ),
        );
      case 3:
      default:
        return Padding(
          key: const ValueKey('step3'),
          padding: const EdgeInsets.all(16),
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recipe Summary', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text('Method: ${_method.name}', style: const TextStyle(color: Colors.black87)),
                    Text('Batch Size: ${_selectedBatchSize}kg', style: const TextStyle(color: Colors.black87)),
                    if ((_selectedCrop ?? '').isNotEmpty)
                      Text('Crop target: ${_selectedCrop!}', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 8),
                    const Text('Selected ingredients:', style: TextStyle(color: Colors.black)),
                    const SizedBox(height: 8),
                    _SelectedIngredientGrid(
                      ingredients: _resolveSelectedIngredients(context),
                      cache: _imageUrlCache,
                    ),
                      const SizedBox(height: 16),
                      // Info box about automatic fermentation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withAlpha((0.3 * 255).round())),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Click "Start Fermentation" to automatically create a fermentation log and begin tracking your fermentation process.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // padding for bottom bar
                    ],
                  ),
                ),
        );
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    // Final step: show actions instead of Back/Done
    if (_step == 3) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _saveDraft(context),
                child: const Text('Save as Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => _proceedToStart(context),
                child: _saving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Fermentation'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton(
              onPressed: () => setState(() => _step = _step - 1),
              child: const Text('Back'),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                // Validation per step
                if (_step == 0) {
                  final hasName = _nameCtrl.text.trim().isNotEmpty;
                  final hasCrop = (_selectedCrop ?? '').trim().isNotEmpty;
                  if (!hasName || !hasCrop) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide recipe name and crop target.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
                if (_step == 1 && _selectedIds.isEmpty) {
                  return; // require at least one ingredient
                }
                if (_step < 3) {
                  setState(() => _step = _step + 1);
                }
              },
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft(BuildContext context) async {
    setState(() => _saving = true);
    try {
      final recipesRepo = context.read<RecipesRepo>();
      final auth = context.read<AuthProvider>();
      final owner = auth.currentUser?.uid ?? '';

      if (owner.isEmpty) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save recipes'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final generated = _generateRecipe(ownerUid: owner);
      await recipesRepo.createRecipe(generated);
      
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _proceedToStart(BuildContext context) async {
    try {
      final auth = context.read<AuthProvider>();
      final owner = auth.currentUser?.uid ?? '';
      
      if (owner.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to start fermentation'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      setState(() => _saving = true);

      // Generate recipe and save it first
      final generated = _generateRecipe(ownerUid: owner);
      final recipesRepo = context.read<RecipesRepo>();
      await recipesRepo.createRecipe(generated);

      // Create fermentation log automatically
      await _createAutoFermentationLog(context, generated, owner);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved and fermentation started automatically!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start fermentation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Recipe _generateRecipe({required String ownerUid}) {
    final ingredients = _resolveSelectedIngredients(context);
    List<RecipeIngredient> base = _baselineFor(_method, ingredients);
    if (base.isEmpty && ingredients.isNotEmpty) {
      // Fallback: evenly distribute material weight among selected ingredients and add sugar
      const String unit = 'kg';
      final double total = _selectedBatchSize;
      // Both FFJ and FPJ use 1:1 ratio: total represents material weight, sugar is equal weight
      final double materialWeight = total; // Total represents material weight
      final double sugarWeight = total; // Equal weight to material
      final double perIngredient = materialWeight / ingredients.length;
      base = [
        for (final ing in ingredients)
          RecipeIngredient(
            ingredientId: ing.id,
            name: ing.name,
            amount: double.parse(perIngredient.toStringAsFixed(2)),
            unit: unit,
          ),
        RecipeIngredient(
          ingredientId: 'brown_sugar',
          name: 'Brown sugar',
          amount: double.parse(sugarWeight.toStringAsFixed(2)),
          unit: unit,
        ),
      ];
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Build human-friendly name and description from selections
    final selectedNames = ingredients.map((e) => e.name).toList();
    final crop = (_selectedCrop ?? '').trim();
    String friendlyName;
    if (selectedNames.isEmpty) {
      friendlyName = _method.name;
    } else if (selectedNames.length == 1) {
      friendlyName = '${_method.name} - ${selectedNames.first}';
    } else if (selectedNames.length == 2) {
      friendlyName = '${_method.name} - ${selectedNames[0]}, ${selectedNames[1]}';
    } else {
      friendlyName = '${_method.name} - ${selectedNames[0]}, ${selectedNames[1]} +${selectedNames.length - 2}';
    }
    if (crop.isNotEmpty) {
      friendlyName = '$friendlyName for $crop';
    }
    
    // Generate step-by-step procedure for the draft
    final guide = FermentationGuideService.generateGuide(
      method: _method,
      ingredients: ingredients,
      cropTarget: (_selectedCrop ?? '').trim(),
      totalWeight: _selectedBatchSize,
    );
    
    // Convert GuideStep to RecipeStep
    final recipeSteps = guide.steps.map((guideStep) => RecipeStep(
      order: guideStep.order,
      text: '${guideStep.title}\n\n${guideStep.description}\n\nDetailed Instructions:\n${guideStep.details.map((detail) => '• $detail').join('\n')}${guideStep.tips.isNotEmpty ? '\n\nTips:\n${guideStep.tips.map((tip) => '• $tip').join('\n')}' : ''}',
    )).toList();
    
    return Recipe(
      id: id,
      ownerUid: ownerUid,
      name: (_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : friendlyName),
      description: 'Ingredients: ${selectedNames.isEmpty ? 'None' : selectedNames.join(', ')}${crop.isNotEmpty ? ' | Crop: $crop' : ''} | Batch: ${_selectedBatchSize.toStringAsFixed(1)} kg',
      method: _method,
      cropTarget: crop,
      ingredients: base,
      steps: recipeSteps, // Include step-by-step procedure in draft
      visibility: RecipeVisibility.private,
      isStandard: false,
      likes: 0,
      avgRating: 0.0,
      totalRatings: 0,
      imageUrls: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<RecipeIngredient> _baselineFor(RecipeMethod method, List<Ingredient> ingredients) {
    // Enhanced baseline ratios based on fermentation best practices
    const String unit = 'kg';
    final double total = _selectedBatchSize; // Use selected batch size
    if (ingredients.isEmpty) return const <RecipeIngredient>[];

    // Both FFJ and FPJ use 1:1 ratio: total represents material weight, sugar is equal weight
    final double materialWeight = total; // Total represents material weight
    final double sugarWeight = total; // Equal weight to material

    // Distribute material weight based on ingredient characteristics
    final Map<String, double> ingredientWeights = _calculateIngredientWeights(ingredients, method, materialWeight);
    
    final generated = <RecipeIngredient>[
      for (final entry in ingredientWeights.entries)
        RecipeIngredient(
          ingredientId: entry.key,
          name: _getIngredientName(entry.key, ingredients),
          amount: entry.value,
          unit: unit,
        ),
      RecipeIngredient(ingredientId: 'brown_sugar', name: 'Brown sugar', amount: sugarWeight, unit: unit),
    ];
    return generated;
  }

  Map<String, double> _calculateIngredientWeights(List<Ingredient> ingredients, RecipeMethod method, double totalWeight) {
    final weights = <String, double>{};
    
    if (ingredients.isEmpty) return weights;
    
    // Calculate base weight per ingredient
    double baseWeight = totalWeight / ingredients.length;
    
    // Adjust weights based on ingredient characteristics
    for (final ingredient in ingredients) {
      double adjustedWeight = baseWeight;
      
      // Adjust based on ingredient category and method
      if (method == RecipeMethod.ffj) {
        if (ingredient.category.toLowerCase().contains('fruit')) {
          adjustedWeight *= 1.2; // Fruits get slightly more weight in FFJ
        } else if (ingredient.category.toLowerCase().contains('flower')) {
          adjustedWeight *= 0.8; // Flowers get less weight
        }
      } else if (method == RecipeMethod.fpj) {
        if (ingredient.category.toLowerCase().contains('plant')) {
          adjustedWeight *= 1.1; // Plants get slightly more weight in FPJ
        } else if (ingredient.category.toLowerCase().contains('weed')) {
          adjustedWeight *= 1.0; // Weeds are good as-is
        }
      }
      
      // Adjust based on nutrient density (simple heuristic)
      if (ingredient.name.toLowerCase().contains('moringa') || 
          ingredient.name.toLowerCase().contains('malunggay')) {
        adjustedWeight *= 0.9; // Highly nutritious, need less
      } else if (ingredient.name.toLowerCase().contains('kangkong') ||
                 ingredient.name.toLowerCase().contains('kamote')) {
        adjustedWeight *= 1.1; // Good but need more for fermentation
      }
      
      weights[ingredient.id] = adjustedWeight;
    }
    
    // Normalize weights to maintain total
    final totalCalculated = weights.values.fold(0.0, (total, weight) => total + weight);
    final factor = totalWeight / totalCalculated;
    
    for (final key in weights.keys) {
      weights[key] = (weights[key]! * factor).clamp(0.1, totalWeight * 0.8); // Min 0.1kg, max 80% of total
    }
    
    return weights;
  }

  String _getIngredientName(String ingredientId, List<Ingredient> ingredients) {
    final ingredient = ingredients.firstWhere(
      (ing) => ing.id == ingredientId,
      orElse: () => Ingredient(
        id: ingredientId,
        name: 'Unknown Ingredient',
        category: 'Unknown',
        recommendedFor: const [],
        precautions: const [],
        createdAt: DateTime.now(),
      ),
    );
    return ingredient.name;
  }


  List<Ingredient> _resolveSelectedIngredients(BuildContext context) {
    final providerAll = context.read<RecipeProvider>().allIngredients;
    final byId = <String, Ingredient>{
      for (final i in providerAll) i.id: i,
      ..._localAdded,
    };
    return [
      for (final id in _selectedIds)
        if (byId.containsKey(id)) byId[id]!
    ];
  }

  Future<void> _createAutoFermentationLog(BuildContext context, Recipe recipe, String ownerUid) async {
    try {
      final fermentationRepo = context.read<FermentationRepo>();
      final notificationService = context.read<NotificationService>();
      
      // Convert recipe method to fermentation method
      final fermentationMethod = recipe.method == RecipeMethod.ffj 
          ? FermentationMethod.ffj 
          : FermentationMethod.fpj;
      
      // Create fermentation ingredients from recipe ingredients
      final fermentationIngredients = recipe.ingredients.map((ingredient) => 
        FermentationIngredient(
          name: ingredient.name,
          amount: ingredient.amount,
          unit: ingredient.unit,
        )
      ).toList();
      
      // Generate default stages based on method
      final stages = _generateDefaultStages(fermentationMethod);
      
      // Create fermentation title from recipe
      final fermentationTitle = '${recipe.name} - ${recipe.cropTarget}';
      
      // Create the fermentation log
      final fermentationLog = FermentationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerUid: ownerUid,
        recipeId: recipe.id, // Link to the recipe
        title: fermentationTitle,
        method: fermentationMethod,
        ingredients: fermentationIngredients,
        startAt: DateTime.now(),
        stages: stages,
        currentStage: 0,
        status: FermentationStatus.active,
        notes: 'Auto-created from recipe: ${recipe.name}',
        photos: const <String>[],
        alertsEnabled: true,
        createdAt: DateTime.now(),
      );
      
      // Save the fermentation log
      await fermentationRepo.createFermentationLog(fermentationLog);
      
      // Schedule notifications if alerts are enabled
      await notificationService.scheduleFermentationNotifications(
        fermentationLog.id,
        fermentationLog.title,
        stages.map((s) => s.toMap()).toList(),
        fermentationLog.startAt,
      );
      
    } catch (e) {
      throw Exception('Failed to create fermentation log: $e');
    }
  }

  List<FermentationStage> _generateDefaultStages(FermentationMethod method) {
    if (method == FermentationMethod.ffj) {
      return const [
        FermentationStage(day: 0, label: 'Day 1', action: 'Mix fruits and sugar'),
        FermentationStage(day: 2, label: 'Day 3', action: 'Stir mixture and check aroma'),
        FermentationStage(day: 6, label: 'Day 7', action: 'Strain and bottle the juice'),
      ];
    } else {
      return const [
        FermentationStage(day: 0, label: 'Day 1', action: 'Mix plant materials and sugar'),
        FermentationStage(day: 2, label: 'Day 3', action: 'Stir and check fermentation'),
        FermentationStage(day: 6, label: 'Day 7', action: 'Strain and store'),
      ];
    }
  }
}

class _RatiosAndSteps extends StatelessWidget {
  final RecipeMethod method;
  final List<Ingredient> selected;
  final double batchSize;
  const _RatiosAndSteps({required this.method, required this.selected, required this.batchSize});

  @override
  Widget build(BuildContext context) {
    final totalWeight = batchSize; // Use selected batch size
    // Both FFJ and FPJ use 1:1 ratio (batch size = material weight, sugar = equal weight)
    final double materialWeight = totalWeight; // Batch size represents material weight
    final double sugarWeight = totalWeight; // Equal weight to material

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Automatic Recipe Generation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        
        // Recipe overview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NatureColors.lightGreen.withAlpha((0.3 * 255).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${method.name} Recipe Overview',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                method == RecipeMethod.fpj 
                    ? 'Plant Material: ${totalWeight.toStringAsFixed(1)} kg (Total: ${(totalWeight * 2).toStringAsFixed(1)} kg)'
                    : 'Fruit Material: ${totalWeight.toStringAsFixed(1)} kg (Total: ${(totalWeight * 2).toStringAsFixed(1)} kg)',
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                '${method == RecipeMethod.fpj ? 'Plant' : 'Fruit'} Materials: ${materialWeight.toStringAsFixed(1)} kg (50%)',
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                'Brown Sugar: ${sugarWeight.toStringAsFixed(1)} kg (50%)',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Selected ingredients preview
        if (selected.isNotEmpty) ...[
          Text(
            'Selected Ingredients (${selected.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ingredient in selected)
                Chip(
                  label: Text(
                    ingredient.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Method-specific information
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: method == RecipeMethod.ffj 
                ? Colors.orange.withAlpha((0.1 * 255).round())
                : Colors.green.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    method == RecipeMethod.ffj ? Icons.local_fire_department : Icons.eco,
                    color: method == RecipeMethod.ffj ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method == RecipeMethod.ffj ? 'FFJ (Fermented Fruit Juice)' : 'FPJ (Fermented Plant Juice)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                method == RecipeMethod.ffj
                    ? '• Uses ripe fruits rich in natural sugars\n'
                      '• Provides energy and nutrients to plants\n'
                      '• Best for fruiting and flowering plants\n'
                      '• Fermentation time: 7-10 days'
                    : '• Uses young plant materials rich in growth hormones\n'
                      '• Stimulates plant growth and development\n'
                      '• Best for vegetative growth and seedlings\n'
                      '• Fermentation time: 7 days',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Fermentation tips
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Fermentation Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Temperature: 20-25°C (room temperature)\n'
                '• Location: Cool, dark place away from direct sunlight\n'
                '• Stirring: 2-3 times daily for first 3 days\n'
                '• Cover: Use breathable material (paper/cloth), not airtight\n'
                '• Storage: Can be stored in refrigerator for up to 6 months',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Step-by-step guide button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openStepByStepGuide(context, method, selected),
            icon: const Icon(Icons.timeline),
            label: const Text('View Step-by-Step Guide'),
            style: ElevatedButton.styleFrom(
              backgroundColor: method == RecipeMethod.ffj 
                  ? Colors.orange 
                  : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        const _SafetyNote(),
      ],
    );
  }
  
  void _openStepByStepGuide(BuildContext context, RecipeMethod method, List<Ingredient> selected) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FermentationGuideScreen(
          method: method,
          ingredients: selected,
          cropTarget: 'Selected crops',
          totalWeight: batchSize,
        ),
      ),
    );
  }
}

class _IngredientSelectionWidget extends StatefulWidget {
  final List<Ingredient> allIngredients;
  final RecipeMethod method;
  final Set<String> selectedIds;
  final Function(Set<String>) onSelectionChanged;

  const _IngredientSelectionWidget({
    required this.allIngredients,
    required this.method,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<_IngredientSelectionWidget> createState() => _IngredientSelectionWidgetState();
}

class _IngredientSelectionWidgetState extends State<_IngredientSelectionWidget> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  final Map<String, String?> _imageUrlCache = <String, String?>{}; // ingredientId -> imageUrl

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  void _updateCategories() {
    // Only show categories that have ingredients AND match the selected method
    final categoryCounts = <String, int>{};
    
    // First filter ingredients by method
    List<Ingredient> methodFilteredIngredients = widget.allIngredients;
    if (widget.method == RecipeMethod.ffj) {
      methodFilteredIngredients = widget.allIngredients.where((i) => 
        i.category.toUpperCase() == 'FFJ' ||
        i.category.toLowerCase().contains('fruit') ||
        i.category.toLowerCase().contains('flower') ||
        i.name.toLowerCase().contains('fruit') ||
        i.name.toLowerCase().contains('banana') ||
        i.name.toLowerCase().contains('papaya') ||
        i.name.toLowerCase().contains('mango') ||
        i.name.toLowerCase().contains('citrus') ||
        i.name.toLowerCase().contains('apple')
      ).toList();
    } else if (widget.method == RecipeMethod.fpj) {
      methodFilteredIngredients = widget.allIngredients.where((i) => 
        i.category.toUpperCase() == 'FPJ' ||
        i.category.toLowerCase().contains('plant') ||
        i.category.toLowerCase().contains('leaf') ||
        i.category.toLowerCase().contains('weed') ||
        i.name.toLowerCase().contains('young') ||
        i.name.toLowerCase().contains('leaf') ||
        i.name.toLowerCase().contains('tip') ||
        i.name.toLowerCase().contains('moringa') ||
        i.name.toLowerCase().contains('malunggay') ||
        i.name.toLowerCase().contains('kangkong')
      ).toList();
    }
    
    // Count categories from method-filtered ingredients
    for (final ingredient in methodFilteredIngredients) {
      categoryCounts[ingredient.category] = (categoryCounts[ingredient.category] ?? 0) + 1;
    }
    
    // Filter out categories with no ingredients
    final categories = categoryCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
    categories.sort();
    
    setState(() {
      _categories = ['All', ...categories];
      // Reset to 'All' if current selection is no longer valid
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }
    });
  }

  List<Ingredient> get _filteredIngredients {
    List<Ingredient> list = widget.allIngredients;

    // Strict filtering by method - only show ingredients that match the selected method
    if (widget.method == RecipeMethod.ffj) {
      // For FFJ, only show ingredients with category 'FFJ' or fruit-related ingredients
      list = list.where((i) => 
        i.category.toUpperCase() == 'FFJ' ||
        i.category.toLowerCase().contains('fruit') ||
        i.category.toLowerCase().contains('flower') ||
        i.name.toLowerCase().contains('fruit') ||
        i.name.toLowerCase().contains('banana') ||
        i.name.toLowerCase().contains('papaya') ||
        i.name.toLowerCase().contains('mango') ||
        i.name.toLowerCase().contains('citrus') ||
        i.name.toLowerCase().contains('apple')
      ).toList();
    } else if (widget.method == RecipeMethod.fpj) {
      // For FPJ, only show ingredients with category 'FPJ' or plant-related ingredients
      list = list.where((i) => 
        i.category.toUpperCase() == 'FPJ' ||
        i.category.toLowerCase().contains('plant') ||
        i.category.toLowerCase().contains('leaf') ||
        i.category.toLowerCase().contains('weed') ||
        i.name.toLowerCase().contains('young') ||
        i.name.toLowerCase().contains('leaf') ||
        i.name.toLowerCase().contains('tip') ||
        i.name.toLowerCase().contains('moringa') ||
        i.name.toLowerCase().contains('malunggay') ||
        i.name.toLowerCase().contains('kangkong')
      ).toList();
    }

    // Filter by category (if user selects a specific category within the method)
    if (_selectedCategory != 'All') {
      list = list.where((ing) => ing.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((ing) => 
        ing.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        ing.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
      ).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredIngredients = _filteredIngredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            labelText: 'Search ingredients...',
            labelStyle: const TextStyle(color: Colors.black),
            floatingLabelStyle: const TextStyle(color: Colors.black),
            hintText: 'e.g., banana, moringa, young leaves',
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: const Icon(Icons.search, color: NatureColors.lightGreen),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: NatureColors.lightGreen, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: NatureColors.lightGreen.withAlpha((0.5 * 255).round()), width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: NatureColors.lightGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Category filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = selected ? category : 'All');
                    },
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Selected count
        Text(
          'Selected: ${widget.selectedIds.length} ingredients',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Ingredients list
        if (filteredIngredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No ingredients found matching your criteria. Try adjusting your search or category filter.',
              style: TextStyle(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: NatureColors.lightGreen.withAlpha((0.3 * 255).round())),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: filteredIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = filteredIngredients[index];
                  final isSelected = widget.selectedIds.contains(ingredient.id);
                  return GestureDetector(
                    onTap: () {
                      final newSelection = Set<String>.from(widget.selectedIds);
                      if (isSelected) {
                        newSelection.remove(ingredient.id);
                      } else {
                        newSelection.add(ingredient.id);
                      }
                      widget.onSelectionChanged(newSelection);
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _IngredientImageTile(
                              ingredientId: ingredient.id,
                              nameFallback: ingredient.name,
                              cache: _imageUrlCache,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ingredient.category,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                ingredient.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: isSelected ? NatureColors.lightGreen : Colors.white,
                              child: Icon(
                                isSelected ? Icons.check : Icons.add,
                                size: 18,
                                color: isSelected ? Colors.white : NatureColors.lightGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Method-specific tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.method == RecipeMethod.ffj ? 'FFJ Tips:' : 'FPJ Tips:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.method == RecipeMethod.ffj 
                  ? '• Choose ripe, sweet fruits for best fermentation\n'
                    '• Bananas, papayas, and citrus work well\n'
                    '• Avoid overripe or spoiled fruits'
                  : '• Use young, fast-growing plant tips\n'
                    '• Moringa, kamote tops, and weeds are excellent\n'
                    '• Harvest in early morning for best results',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IngredientImageTile extends StatefulWidget {
  final String ingredientId;
  final String nameFallback;
  final Map<String, String?> cache;

  const _IngredientImageTile({
    required this.ingredientId,
    required this.nameFallback,
    required this.cache,
  });

  @override
  State<_IngredientImageTile> createState() => _IngredientImageTileState();
}

class _IngredientImageTileState extends State<_IngredientImageTile> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _url = widget.cache[widget.ingredientId];
    if (_url == null) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('ingredients').doc(widget.ingredientId).get();
      final data = doc.data();
      final url = data != null ? (data['imageUrl'] as String? ?? '') : '';
      if (mounted) {
        setState(() => _url = url);
        widget.cache[widget.ingredientId] = url;
      }
    } catch (_) {
      // ignore and show placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return Container(color: Colors.grey[200]);
    }
    if (_url!.isEmpty) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      );
    }
    return Image.network(
      _url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        );
      },
    );
  }
}

class _SelectedIngredientGrid extends StatelessWidget {
  final List<Ingredient> ingredients;
  final Map<String, String?> cache;

  const _SelectedIngredientGrid({
    required this.ingredients,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const Text('No ingredients selected yet', style: TextStyle(color: Colors.black54));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ing = ingredients[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _IngredientImageTile(
                  ingredientId: ing.id,
                  nameFallback: ing.name,
                  cache: cache,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    ing.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NatureColors.lightGreen.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Safety: Use clean tools, avoid contaminated materials, and keep mixtures away from direct sunlight. If unsure, consult local guidelines.',
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}


