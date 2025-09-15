import '../models/ingredient.dart';
import '../models/recipe.dart';

class FermentationGuideService {
  // Baseline ratios for FFJ and FPJ
  static const Map<RecipeMethod, Map<String, double>> baselineRatios = {
    RecipeMethod.FFJ: {
      'material': 2.0,  // 2 parts fruit material
      'sugar': 1.0,     // 1 part brown sugar
      'total': 3.0,     // Total parts
    },
    RecipeMethod.FPJ: {
      'material': 2.0,  // 2 parts plant material
      'sugar': 1.0,     // 1 part brown sugar
      'total': 3.0,     // Total parts
    },
  };

  // Method-specific characteristics
  static const Map<RecipeMethod, Map<String, dynamic>> methodCharacteristics = {
    RecipeMethod.FFJ: {
      'name': 'Fermented Fruit Juice',
      'description': 'For flowering and fruit development',
      'icon': '🍌',
      'fermentationDays': 7,
      'idealTemperature': '20-25°C',
      'materialType': 'fruits and flowers',
      'benefits': [
        'Promotes flowering and fruiting',
        'Rich in natural sugars and enzymes',
        'Enhances fruit sweetness and size',
        'Boosts plant immunity',
      ],
    },
    RecipeMethod.FPJ: {
      'name': 'Fermented Plant Juice',
      'description': 'For general plant growth and development',
      'icon': '🌱',
      'fermentationDays': 7,
      'idealTemperature': '20-25°C',
      'materialType': 'young plant shoots and leaves',
      'benefits': [
        'Promotes vigorous plant growth',
        'Rich in growth hormones and nutrients',
        'Enhances root development',
        'Improves plant structure',
      ],
    },
  };

  /// Generate comprehensive step-by-step guide for FFJ/FPJ
  static FermentationGuide generateGuide({
    required RecipeMethod method,
    required List<Ingredient> ingredients,
    required String cropTarget,
    double totalWeight = 3.0, // kg
  }) {
    final characteristics = methodCharacteristics[method]!;
    final ratios = baselineRatios[method]!;
    
    // Calculate ingredient weights
    final ingredientWeights = _calculateIngredientWeights(ingredients, method, totalWeight);
    
    // Generate steps
    final steps = _generateSteps(method, ingredients, totalWeight);
    
    // Generate tips and warnings
    final tips = _generateTips(method, ingredients);
    final warnings = _generateWarnings(method, ingredients);
    
    return FermentationGuide(
      method: method,
      name: characteristics['name'],
      description: characteristics['description'],
      icon: characteristics['icon'],
      cropTarget: cropTarget,
      totalWeight: totalWeight,
      ratios: ratios,
      ingredients: ingredientWeights,
      steps: steps,
      tips: tips,
      warnings: warnings,
      fermentationDays: characteristics['fermentationDays'],
      idealTemperature: characteristics['idealTemperature'],
      benefits: List<String>.from(characteristics['benefits']),
    );
  }

  /// Calculate optimal ingredient weights based on method and characteristics
  static Map<String, double> _calculateIngredientWeights(
    List<Ingredient> ingredients, 
    RecipeMethod method, 
    double totalWeight
  ) {
    final ratios = baselineRatios[method]!;
    final materialWeight = totalWeight * (ratios['material']! / ratios['total']!);
    final sugarWeight = totalWeight * (ratios['sugar']! / ratios['total']!);
    
    final weights = <String, double>{};
    
    if (ingredients.isEmpty) return weights;
    
    // Calculate base weight per ingredient
    double baseWeight = materialWeight / ingredients.length;
    
    // Adjust weights based on ingredient characteristics
    for (final ingredient in ingredients) {
      double adjustedWeight = baseWeight;
      
      // Method-specific adjustments
      if (method == RecipeMethod.FFJ) {
        if (ingredient.category.toLowerCase().contains('fruit')) {
          adjustedWeight *= 1.3; // Fruits are primary in FFJ
        } else if (ingredient.category.toLowerCase().contains('flower')) {
          adjustedWeight *= 0.7; // Flowers are secondary
        }
      } else if (method == RecipeMethod.FPJ) {
        if (ingredient.category.toLowerCase().contains('plant')) {
          adjustedWeight *= 1.2; // Plants are primary in FPJ
        } else if (ingredient.category.toLowerCase().contains('weed')) {
          adjustedWeight *= 1.0; // Weeds are good as-is
        }
      }
      
      // Nutrient density adjustments
      if (ingredient.name.toLowerCase().contains('moringa') || 
          ingredient.name.toLowerCase().contains('malunggay')) {
        adjustedWeight *= 0.8; // Highly nutritious, need less
      } else if (ingredient.name.toLowerCase().contains('kangkong') ||
                 ingredient.name.toLowerCase().contains('kamote')) {
        adjustedWeight *= 1.1; // Good but need more for fermentation
      }
      
      weights[ingredient.id] = adjustedWeight;
    }
    
    // Normalize weights to maintain total
    final totalCalculated = weights.values.fold(0.0, (sum, weight) => sum + weight);
    if (totalCalculated > 0) {
      final factor = materialWeight / totalCalculated;
      for (final key in weights.keys) {
        weights[key] = (weights[key]! * factor).clamp(0.1, materialWeight * 0.8);
      }
    }
    
    // Add brown sugar
    weights['brown_sugar'] = sugarWeight;
    
    return weights;
  }

  /// Generate detailed step-by-step instructions
  static List<GuideStep> _generateSteps(
    RecipeMethod method, 
    List<Ingredient> ingredients, 
    double totalWeight
  ) {
    final characteristics = methodCharacteristics[method]!;
    final materialType = characteristics['materialType'];
    
    return [
      // Preparation Phase
      GuideStep(
        phase: 'Preparation',
        order: 1,
        title: 'Gather Materials and Tools',
        description: 'Collect all necessary materials and prepare your workspace',
        details: [
          'Clean glass jars or food-grade plastic containers (2-3 liters capacity)',
          'Clean cutting board and knife',
          'Measuring scale',
          'Clean cloth or paper for covering',
          'Rubber bands or string',
          'Strainer or clean cloth for filtering',
          'Clean storage bottles',
        ],
        tips: [
          'Use glass containers for better fermentation',
          'Ensure all tools are clean to prevent contamination',
        ],
      ),
      
      GuideStep(
        phase: 'Preparation',
        order: 2,
        title: 'Prepare Workspace',
        description: 'Set up a clean, well-ventilated area for fermentation',
        details: [
          'Choose a cool, dark place (20-25°C)',
          'Avoid direct sunlight',
          'Ensure good air circulation',
          'Clean the work surface thoroughly',
        ],
        tips: [
          'Temperature is crucial for proper fermentation',
          'Avoid areas with strong odors that might affect the process',
        ],
      ),
      
      // Material Preparation Phase
      GuideStep(
        phase: 'Material Preparation',
        order: 3,
        title: 'Select and Clean Materials',
        description: 'Choose the best quality materials for fermentation',
        details: method == RecipeMethod.FFJ ? [
          'Select ripe, sweet fruits (banana, papaya, mango, etc.)',
          'Choose fresh, clean flowers if available',
          'Remove any damaged or rotten parts',
          'Wash thoroughly with clean water',
          'Dry completely before processing',
        ] : [
          'Select young, tender plant shoots and leaves (2-3 months old)',
          'Choose fast-growing plants (moringa, kamote tops, kangkong, etc.)',
          'Remove any diseased or damaged parts',
          'Wash thoroughly with clean water',
          'Dry completely before processing',
        ],
        tips: [
          'Quality of materials directly affects the final product',
          'Use only healthy, disease-free materials',
        ],
      ),
      
      GuideStep(
        phase: 'Material Preparation',
        order: 4,
        title: 'Cut Materials',
        description: 'Cut materials into appropriate sizes for fermentation',
        details: method == RecipeMethod.FFJ ? [
          'Cut fruits into small pieces (1-2 cm)',
          'Remove seeds and hard parts',
          'Cut flowers into smaller pieces',
          'Ensure uniform size for even fermentation',
        ] : [
          'Cut plant materials into small pieces (2-3 cm)',
          'Remove thick stems and hard parts',
          'Use only tender shoots and leaves',
          'Ensure uniform size for even fermentation',
        ],
        tips: [
          'Smaller pieces ferment faster and more evenly',
          'Remove any parts that might cause bitterness',
        ],
      ),
      
      // Mixing Phase
      GuideStep(
        phase: 'Mixing',
        order: 5,
        title: 'Layer Materials and Sugar',
        description: 'Create proper layers for optimal fermentation',
        details: [
          'Place a layer of cut materials at the bottom',
          'Add a layer of brown sugar on top',
          'Repeat layering: materials, then sugar',
          'End with a layer of brown sugar on top',
          'Total ratio: 2 parts materials to 1 part sugar',
        ],
        tips: [
          'Layering ensures even distribution of sugar',
          'The sugar layer on top helps prevent mold',
        ],
      ),
      
      GuideStep(
        phase: 'Mixing',
        order: 6,
        title: 'Mix Thoroughly',
        description: 'Mix all ingredients well to start fermentation',
        details: [
          'Mix all layers together thoroughly',
          'Ensure sugar is evenly distributed',
          'Press down gently to remove air pockets',
          'Leave some space at the top (about 2-3 cm)',
        ],
        tips: [
          'Good mixing is essential for proper fermentation',
          'Don\'t pack too tightly - some air circulation is needed',
        ],
      ),
      
      // Fermentation Phase
      GuideStep(
        phase: 'Fermentation',
        order: 7,
        title: 'Cover and Store',
        description: 'Cover the container properly for fermentation',
        details: [
          'Cover with clean cloth or paper (not airtight)',
          'Secure with rubber band or string',
          'Label with date and contents',
          'Place in cool, dark location (20-25°C)',
        ],
        tips: [
          'Covering prevents contamination while allowing air circulation',
          'Labeling helps track fermentation progress',
        ],
      ),
      
      GuideStep(
        phase: 'Fermentation',
        order: 8,
        title: 'Daily Mixing (First 3 Days)',
        description: 'Mix daily to promote even fermentation',
        details: [
          'Mix 2-3 times daily for the first 3 days',
          'Use clean spoon or hands',
          'Press down gently after mixing',
          'Observe for signs of fermentation (bubbles, aroma)',
        ],
        tips: [
          'Regular mixing prevents mold formation',
          'Stop mixing after 3 days to allow natural fermentation',
        ],
      ),
      
      GuideStep(
        phase: 'Fermentation',
        order: 9,
        title: 'Monitor Fermentation',
        description: 'Watch for proper fermentation signs',
        details: [
          'Check daily for natural mold formation on top',
          'Look for sweet, fermented aroma',
          'Observe bubbling or liquid formation',
          'Fermentation typically takes 7-10 days',
        ],
        tips: [
          'White mold is normal and beneficial',
          'Black or green mold indicates contamination - discard',
        ],
      ),
      
      // Harvesting Phase
      GuideStep(
        phase: 'Harvesting',
        order: 10,
        title: 'Strain the Fermented Juice',
        description: 'Extract the fermented liquid',
        details: [
          'When fermentation is complete (7-10 days)',
          'Strain through clean cloth or fine strainer',
          'Press gently to extract maximum juice',
          'Discard the solid materials',
        ],
        tips: [
          'Don\'t squeeze too hard to avoid bitter taste',
          'The liquid should be clear and sweet-smelling',
        ],
      ),
      
      GuideStep(
        phase: 'Harvesting',
        order: 11,
        title: 'Store the Final Product',
        description: 'Properly store the fermented juice',
        details: [
          'Pour into clean, dry bottles',
          'Leave some space at the top',
          'Store in refrigerator for up to 6 months',
          'Label with date and contents',
        ],
        tips: [
          'Refrigeration extends shelf life',
          'Use clean bottles to prevent contamination',
        ],
      ),
      
      // Usage Phase
      GuideStep(
        phase: 'Usage',
        order: 12,
        title: 'Application Guidelines',
        description: 'How to use the fermented juice effectively',
        details: [
          'Dilute 1-2 tablespoons in 1 liter of water',
          'Apply as foliar spray in early morning or late afternoon',
          'Avoid application during hot midday sun',
          'Use every 7-14 days for best results',
        ],
        tips: [
          'Start with lower concentration and increase gradually',
          'Test on a few plants first to check for any adverse effects',
        ],
      ),
    ];
  }

  /// Generate helpful tips based on method and ingredients
  static List<String> _generateTips(RecipeMethod method, List<Ingredient> ingredients) {
    final tips = <String>[
      'Always use clean, uncontaminated materials',
      'Temperature control is crucial - maintain 20-25°C',
      'Patience is key - don\'t rush the fermentation process',
      'Store in a cool, dark place away from direct sunlight',
      'Use glass containers for better fermentation results',
    ];
    
    if (method == RecipeMethod.FFJ) {
      tips.addAll([
        'Choose the sweetest, ripest fruits for best results',
        'Fruits with high sugar content ferment better',
        'Remove all seeds and hard parts before processing',
        'The sweeter the fruit, the better the final product',
      ]);
    } else {
      tips.addAll([
        'Use only young, tender plant materials',
        'Avoid woody or mature plant parts',
        'Harvest materials in the early morning for best quality',
        'Fresh materials produce better fermentation results',
      ]);
    }
    
    // Add ingredient-specific tips
    for (final ingredient in ingredients) {
      if (ingredient.name.toLowerCase().contains('moringa')) {
        tips.add('Moringa is highly nutritious - use sparingly in the mix');
      } else if (ingredient.name.toLowerCase().contains('banana')) {
        tips.add('Banana peels can also be used for additional nutrients');
      }
    }
    
    return tips;
  }

  /// Generate important warnings
  static List<String> _generateWarnings(RecipeMethod method, List<Ingredient> ingredients) {
    return [
      'Never use materials treated with pesticides or chemicals',
      'Discard immediately if you see black, green, or fuzzy mold',
      'Stop fermentation if you notice foul or rotten smell',
      'Do not use if the final product is cloudy or has off-putting odor',
      'Keep away from children and pets',
      'Use only for plants - not for human consumption',
      'Wash hands thoroughly after handling',
      'Store in clearly labeled containers to avoid confusion',
    ];
  }
}

/// Comprehensive fermentation guide data class
class FermentationGuide {
  final RecipeMethod method;
  final String name;
  final String description;
  final String icon;
  final String cropTarget;
  final double totalWeight;
  final Map<String, double> ratios;
  final Map<String, double> ingredients;
  final List<GuideStep> steps;
  final List<String> tips;
  final List<String> warnings;
  final int fermentationDays;
  final String idealTemperature;
  final List<String> benefits;

  const FermentationGuide({
    required this.method,
    required this.name,
    required this.description,
    required this.icon,
    required this.cropTarget,
    required this.totalWeight,
    required this.ratios,
    required this.ingredients,
    required this.steps,
    required this.tips,
    required this.warnings,
    required this.fermentationDays,
    required this.idealTemperature,
    required this.benefits,
  });
}

/// Individual step in the fermentation guide
class GuideStep {
  final String phase;
  final int order;
  final String title;
  final String description;
  final List<String> details;
  final List<String> tips;

  const GuideStep({
    required this.phase,
    required this.order,
    required this.title,
    required this.description,
    required this.details,
    required this.tips,
  });
}
