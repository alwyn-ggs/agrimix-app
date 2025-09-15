import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recipe_provider.dart';
import '../../repositories/ingredients_repo.dart';
import '../../repositories/recipes_repo.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../providers/auth_provider.dart';
import '../../router.dart';
import '../../theme/theme.dart';
import '../../services/fermentation_guide_service.dart';
import 'fermentation_guide_screen.dart';

class FormulateRecipeFlow extends StatefulWidget {
  const FormulateRecipeFlow({super.key});

  @override
  State<FormulateRecipeFlow> createState() => _FormulateRecipeFlowState();
}

class _FormulateRecipeFlowState extends State<FormulateRecipeFlow> {
  int _step = 0;
  RecipeMethod _method = RecipeMethod.FFJ;
  Set<String> _selectedIds = <String>{};
  final TextEditingController _cropCtrl = TextEditingController();
  final TextEditingController _newIngCtrl = TextEditingController();
  bool _saving = false;
  final Map<String, Ingredient> _localAdded = <String, Ingredient>{};
  
  // Batch size options
  final List<double> _batchSizes = [1.5, 3.0, 6.0, 9.0];
  final List<String> _batchSizeLabels = ['Small (1.5kg)', 'Medium (3kg)', 'Large (6kg)', 'Extra Large (9kg)'];
  double _selectedBatchSize = 3.0;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _newIngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsRepo = context.read<IngredientsRepo>();
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulate Recipe', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.white,
      body: Stepper(
        currentStep: _step,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Choose method', style: TextStyle(color: Colors.black)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToggleButtons(
                  isSelected: [
                    _method == RecipeMethod.FFJ,
                    _method == RecipeMethod.FPJ,
                  ],
                  onPressed: (i) => setState(() => _method = i == 0 ? RecipeMethod.FFJ : RecipeMethod.FPJ),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('FFJ', style: TextStyle(color: Colors.black))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('FPJ', style: TextStyle(color: Colors.black))),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Batch Size Selection
                DropdownButtonFormField<double>(
                  value: _selectedBatchSize,
                  onChanged: (value) => setState(() => _selectedBatchSize = value!),
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Batch Size',
                    labelStyle: const TextStyle(color: Colors.black),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen.withOpacity(0.5), width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: List.generate(_batchSizes.length, (index) {
                    return DropdownMenuItem<double>(
                      value: _batchSizes[index],
                      child: Container(
                        color: Colors.white,
                        child: Text(
                          _batchSizeLabels[index],
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 12),
                TextField(
                  controller: _cropCtrl,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    labelText: 'Crop target (optional)',
                    labelStyle: const TextStyle(color: Colors.black),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    hintText: 'e.g., tomato, leafy greens',
                    hintStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen.withOpacity(0.5), width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: NatureColors.lightGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const _SafetyNote(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
            isActive: _step == 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Pick ingredients', style: TextStyle(color: Colors.black)),
            content: Builder(builder: (context) {
              final all = recipeProvider.allIngredients;
              if (all.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    SizedBox(height: 8),
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 12),
                    Center(child: Text('Loading ingredients...')),
                  ],
                );
              }
              return Column(
                children: [
                  _IngredientSelectionWidget(
                    allIngredients: all,
                    method: _method,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (selectedIds) => setState(() => _selectedIds = selectedIds),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _selectedIds.isEmpty ? null : () => setState(() => _step = 2),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              );
            }),
            isActive: _step == 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Ratios & steps', style: TextStyle(color: Colors.black)),
            content: Column(
              children: [
                _RatiosAndSteps(
                  method: _method, 
                  selected: _resolveSelectedIngredients(context),
                  batchSize: _selectedBatchSize,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => setState(() => _step = 3),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
            isActive: _step == 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Save or start', style: TextStyle(color: Colors.black)),
            content: _saving
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recipe Summary', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text('Method: ${_method.name}', style: const TextStyle(color: Colors.black87)),
                      Text('Batch Size: ${_selectedBatchSize}kg', style: const TextStyle(color: Colors.black87)),
                      if (_cropCtrl.text.trim().isNotEmpty)
                        Text('Crop target: ${_cropCtrl.text.trim()}', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Text('Selected ingredients:', style: TextStyle(color: Colors.black)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final ing in _resolveSelectedIngredients(context))
                            Chip(label: Text(ing.name)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
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
                              onPressed: () => _proceedToStart(context),
                              child: const Text('Proceed to Start'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            isActive: _step == 3,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  void _next(BuildContext context) {
    if (_step == 1 && _selectedIds.isEmpty) return; // require at least one ingredient
    if (_step < 3) setState(() => _step += 1);
  }

  Future<void> _saveDraft(BuildContext context) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _step = 1);
      return;
    }
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

  void _proceedToStart(BuildContext context) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _step = 1);
      return;
    }
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

      final generated = _generateRecipe(ownerUid: owner);
      try {
        // Persist the draft so it appears under My Recipes > Drafts
        final recipesRepo = context.read<RecipesRepo>();
        await recipesRepo.createRecipe(generated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft saved. Opening fermentation start...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (_) {
        // Continue even if save fails; the next screen can still use the local draft
      }
      if (mounted) {
        Navigator.of(context).pushNamed(Routes.newLog, arguments: {
          'draftRecipe': {
            'id': generated.id,
            'data': generated.toMap(),
          },
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start fermentation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Recipe _generateRecipe({required String ownerUid}) {
    final ingredients = _resolveSelectedIngredients(context);
    final base = _baselineFor(_method, ingredients);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = '${_method.name} formula';
    
    // Generate step-by-step procedure for the draft
    final guide = FermentationGuideService.generateGuide(
      method: _method,
      ingredients: ingredients,
      cropTarget: _cropCtrl.text.trim(),
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
      name: name,
      description: 'Auto-generated ${_method.name} formula for ${_cropCtrl.text.trim()}',
      method: _method,
      cropTarget: _cropCtrl.text.trim(),
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

    // Method-specific ratios based on fermentation science
    final double sugarParts = method == RecipeMethod.FFJ ? 1.0 : 1.0;
    final double materialParts = method == RecipeMethod.FFJ ? 2.0 : 2.0; // More material for better fermentation
    final double materialWeight = total * (materialParts / (materialParts + sugarParts));
    final double sugarWeight = total - materialWeight;

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
      if (method == RecipeMethod.FFJ) {
        if (ingredient.category.toLowerCase().contains('fruit')) {
          adjustedWeight *= 1.2; // Fruits get slightly more weight in FFJ
        } else if (ingredient.category.toLowerCase().contains('flower')) {
          adjustedWeight *= 0.8; // Flowers get less weight
        }
      } else if (method == RecipeMethod.FPJ) {
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
    final totalCalculated = weights.values.fold(0.0, (sum, weight) => sum + weight);
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

  static String _slugify(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

class _RatiosAndSteps extends StatelessWidget {
  final RecipeMethod method;
  final List<Ingredient> selected;
  final double batchSize;
  const _RatiosAndSteps({required this.method, required this.selected, required this.batchSize});

  @override
  Widget build(BuildContext context) {
    final totalWeight = batchSize; // Use selected batch size
    final materialWeight = totalWeight * (2.0 / 3.0); // 2/3 for materials
    final sugarWeight = totalWeight * (1.0 / 3.0); // 1/3 for sugar

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic Recipe Generation',
          style: const TextStyle(
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
            color: NatureColors.lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NatureColors.lightGreen.withOpacity(0.3)),
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
                'Total Batch Size: ${totalWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                'Plant Materials: ${materialWeight.toStringAsFixed(1)} kg (${(materialWeight/totalWeight*100).toStringAsFixed(0)}%)',
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                'Brown Sugar: ${sugarWeight.toStringAsFixed(1)} kg (${(sugarWeight/totalWeight*100).toStringAsFixed(0)}%)',
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
                  backgroundColor: NatureColors.lightGreen.withOpacity(0.2),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Method-specific information
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: method == RecipeMethod.FFJ 
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    method == RecipeMethod.FFJ ? Icons.local_fire_department : Icons.eco,
                    color: method == RecipeMethod.FFJ ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method == RecipeMethod.FFJ ? 'FFJ (Fermented Fruit Juice)' : 'FPJ (Fermented Plant Juice)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                method == RecipeMethod.FFJ
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
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
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
              const SizedBox(height: 8),
              const Text(
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
              backgroundColor: method == RecipeMethod.FFJ 
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

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  void _updateCategories() {
    final categories = widget.allIngredients
        .map((ing) => ing.category)
        .toSet()
        .toList();
    categories.sort();
    setState(() {
      _categories = ['All', ...categories];
    });
  }

  List<Ingredient> get _filteredIngredients {
    List<Ingredient> list = widget.allIngredients;

    // Filter by method recommendation
    if (widget.method == RecipeMethod.FFJ) {
      final fruits = list.where((i) => 
        i.category.toLowerCase().contains('fruit') ||
        i.category.toLowerCase().contains('flower') ||
        i.name.toLowerCase().contains('fruit') ||
        i.name.toLowerCase().contains('banana') ||
        i.name.toLowerCase().contains('papaya')
      ).toList();
      if (fruits.isNotEmpty) list = fruits;
    } else {
      final plants = list.where((i) => 
        i.category.toLowerCase().contains('plant') ||
        i.category.toLowerCase().contains('leaf') ||
        i.category.toLowerCase().contains('weed') ||
        i.name.toLowerCase().contains('young') ||
        i.name.toLowerCase().contains('leaf') ||
        i.name.toLowerCase().contains('tip')
      ).toList();
      if (plants.isNotEmpty) list = plants;
    }

    // Filter by category
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
            border: OutlineInputBorder(
              borderSide: BorderSide(color: NatureColors.lightGreen, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: NatureColors.lightGreen.withOpacity(0.5), width: 1),
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
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: NatureColors.lightGreen.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = filteredIngredients[index];
                final isSelected = widget.selectedIds.contains(ingredient.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? NatureColors.lightGreen.withOpacity(0.1) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? NatureColors.lightGreen : Colors.grey[300],
                      child: Icon(
                        isSelected ? Icons.check : Icons.add,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    title: Text(
                      ingredient.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? NatureColors.lightGreen : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category: ${ingredient.category}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        if (ingredient.description != null && ingredient.description!.isNotEmpty)
                          Text(
                            ingredient.description!,
                            style: const TextStyle(color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (ingredient.recommendedFor.isNotEmpty)
                          Wrap(
                            children: [
                              const Text('Recommended for: ', style: TextStyle(color: Colors.black54)),
                              ...ingredient.recommendedFor.take(3).map((crop) => 
                                Text(
                                  '$crop, ',
                                  style: const TextStyle(color: Colors.black87),
                                )
                              ),
                              if (ingredient.recommendedFor.length > 3)
                                Text(
                                  'and ${ingredient.recommendedFor.length - 3} more...',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                            ],
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isSelected ? Icons.remove_circle : Icons.add_circle,
                        color: isSelected ? Colors.red : NatureColors.lightGreen,
                      ),
                      onPressed: () {
                        final newSelection = Set<String>.from(widget.selectedIds);
                        if (isSelected) {
                          newSelection.remove(ingredient.id);
                        } else {
                          newSelection.add(ingredient.id);
                        }
                        widget.onSelectionChanged(newSelection);
                      },
                    ),
                    onTap: () {
                      final newSelection = Set<String>.from(widget.selectedIds);
                      if (isSelected) {
                        newSelection.remove(ingredient.id);
                      } else {
                        newSelection.add(ingredient.id);
                      }
                      widget.onSelectionChanged(newSelection);
                    },
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Method-specific tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NatureColors.lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.method == RecipeMethod.FFJ ? 'FFJ Tips:' : 'FPJ Tips:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.method == RecipeMethod.FFJ 
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

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NatureColors.lightGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Safety: Use clean tools, avoid contaminated materials, and keep mixtures away from direct sunlight. If unsure, consult local guidelines.',
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}


