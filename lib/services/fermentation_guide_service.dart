import '../models/ingredient.dart';
import '../models/recipe.dart';

class FermentationGuideService {
  // Baseline ratios for FFJ and FPJ
  static const Map<RecipeMethod, Map<String, double>> baselineRatios = {
    RecipeMethod.ffj: {
      'material': 1.0,  // 1 part fruit material (equal weight)
      'sugar': 1.0,     // 1 part brown sugar (equal weight)
      'total': 2.0,     // Total parts (but batch size represents material weight only)
    },
    RecipeMethod.fpj: {
      'material': 1.0,  // 1 part plant material (equal weight)
      'sugar': 1.0,     // 1 part brown sugar (equal weight)
      'total': 2.0,     // Total parts (but batch size represents material weight only)
    },
  };

  // Method-specific characteristics
  static const Map<RecipeMethod, Map<String, dynamic>> methodCharacteristics = {
    RecipeMethod.ffj: {
      'name': 'Fermented Fruit Juice',
      'description': 'For flowering and fruit development',
      'icon': '🍌',
      'fermentationDays': 7,
      'idealTemperature': '20-25°C',
      'materialType': 'fruits and flowers',
      'benefits': [
        'Promotes healthy growth of lowland vegetables',
        'Rich in natural sugars and enzymes for better crop development',
        'Enhances vegetable quality and yield',
        'Boosts plant immunity against diseases',
        'Improves soil fertility for vegetable crops',
        'Increases nutrient uptake in leafy vegetables',
      ],
    },
    RecipeMethod.fpj: {
      'name': 'Fermented Plant Juice',
      'description': 'For general plant growth and development',
      'icon': '🌱',
      'fermentationDays': 7,
      'idealTemperature': '20-25°C',
      'materialType': 'young plant shoots and leaves',
      'benefits': [
        'Promotes vigorous growth of lowland vegetables',
        'Rich in growth hormones and nutrients for vegetable crops',
        'Enhances root development in leafy vegetables',
        'Improves plant structure and stem strength',
        'Boosts chlorophyll production in green vegetables',
        'Increases resistance to pests and diseases in vegetables',
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
    // Both FFJ and FPJ use 1:1 ratio: totalWeight represents material weight, sugar is equal weight
    final double materialWeight = totalWeight;
    final double sugarWeight = totalWeight; // Equal weight
    
    final weights = <String, double>{};
    
    if (ingredients.isEmpty) return weights;
    
    // Calculate base weight per ingredient
    double baseWeight = materialWeight / ingredients.length;
    
    // Adjust weights based on ingredient characteristics
    for (final ingredient in ingredients) {
      double adjustedWeight = baseWeight;
      
      // Method-specific adjustments
      if (method == RecipeMethod.ffj) {
        if (ingredient.category.toLowerCase().contains('fruit')) {
          adjustedWeight *= 1.3; // Fruits are primary in FFJ
        } else if (ingredient.category.toLowerCase().contains('flower')) {
          adjustedWeight *= 0.7; // Flowers are secondary
        }
      } else if (method == RecipeMethod.fpj) {
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
    final totalCalculated = weights.values.fold(0.0, (total, weight) => total + weight);
    if (totalCalculated > 0) {
      final factor = materialWeight / totalCalculated;
      for (final key in weights.keys) {
        weights[key] = (weights[key]! * factor).clamp(0.1, materialWeight);
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
    if (method == RecipeMethod.fpj) {
      return _generateFPJSteps(ingredients, totalWeight);
    } else {
      return _generateFFJSteps(ingredients, totalWeight);
    }
  }

  /// Generate FPJ steps following the correct procedure
  static List<GuideStep> _generateFPJSteps(List<Ingredient> ingredients, double totalWeight) {
    return [
      // Material Collection Phase
      const GuideStep(
        phase: 'Material Collection',
        order: 1,
        title: 'Gather Plant Material at Dawn',
        description: 'Collect plant materials early in the morning while dew is still present',
        details: [
          'Collect materials right at dawn while dew is still on them',
          'Focus on new growth and young plant shoots',
          'Choose healthy, disease-free plant materials',
          'Use fast-growing plants (moringa, kamote tops, kangkong, etc.)',
          'Avoid materials that have been exposed to pesticides',
        ],
        tips: [
          'Dew contains beneficial microorganisms',
          'Early morning collection preserves essential substances',
          'New growth has higher nutrient content',
        ],
      ),
      
      // Weighing Phase
      const GuideStep(
        phase: 'Weighing',
        order: 2,
        title: 'Weigh Plant Material and Sugar',
        description: 'Measure equal parts of plant material and brown sugar',
        details: [
          'Weigh the collected plant material',
          'Weigh equal parts brown sugar (1:1 ratio)',
          'Use a clean, accurate scale',
          'Record the weights for reference',
        ],
        tips: [
          'Equal weight ratio ensures proper fermentation',
          'Brown sugar provides food for beneficial microorganisms',
        ],
      ),
      
      // Preparation Phase
      const GuideStep(
        phase: 'Preparation',
        order: 3,
        title: 'Cut Up Plant Material',
        description: 'Cut plant materials into appropriate sizes',
        details: [
          'Cut plant materials into small pieces',
          'Remove thick stems and hard parts',
          'Use only tender shoots and leaves',
          'Work quickly to preserve essential substances',
        ],
        tips: [
          'Smaller pieces allow better sugar penetration',
          'Work quickly to prevent loss of beneficial microbes',
        ],
      ),
      
      // Mixing Phase
      const GuideStep(
        phase: 'Mixing',
        order: 4,
        title: 'Add Materials and Sugar to Container',
        description: 'Combine plant materials with brown sugar quickly',
        details: [
          'Add plant material to large mixing container',
          'Add the brown sugar immediately',
          'Work quickly to not lose essential substances and microbes',
          'Essential substances are released when plants are chopped',
        ],
        tips: [
          'Speed is important to preserve beneficial microorganisms',
          'Use a container large enough for mixing',
        ],
      ),
      
      const GuideStep(
        phase: 'Mixing',
        order: 5,
        title: 'Mix and Stir Thoroughly',
        description: 'Mix all ingredients ensuring complete sugar coverage',
        details: [
          'Mix it all and stir (okay to be rough but not trying to smash it)',
          'Make sure every inch of plant surface area is covered in sugar',
          'It will start to feel wet as sugar draws out moisture',
          'Ensure even distribution throughout the mixture',
        ],
        tips: [
          'Complete sugar coverage prevents spoilage',
          'The mixture should feel wet and sticky',
        ],
      ),
      
      // Fermentation Setup
      const GuideStep(
        phase: 'Fermentation Setup',
        order: 6,
        title: 'Put in Jar with Porous Lid',
        description: 'Transfer mixture to fermentation jar with proper covering',
        details: [
          'Put mixture in jar (ideally about 3/4 full)',
          'Use a porous lid on top (not airtight)',
          'End with a cap of brown sugar covering everything entirely',
          'Ensure sugar covers every visible inch of the mixture',
        ],
        tips: [
          '3/4 full allows space for fermentation gases',
          'Porous lid allows air circulation while preventing contamination',
          'Sugar cap acts as a protective barrier',
        ],
      ),
      
      // Fermentation Phase
      const GuideStep(
        phase: 'Fermentation',
        order: 7,
        title: 'Monitor Fermentation Process',
        description: 'Watch for fermentation completion based on temperature',
        details: [
          'Depending on temperature, this will take 3-10 days',
          'Shorter time in hotter temperatures',
          'Longer time in cooler temperatures',
          'Watch for liquid separation from solid parts',
        ],
        tips: [
          'Temperature directly affects fermentation speed',
          'Liquid separation indicates fermentation is complete',
        ],
      ),
      
      // Harvesting Phase
      const GuideStep(
        phase: 'Harvesting',
        order: 8,
        title: 'Strain the Fermented Juice',
        description: 'Separate liquid FPJ from solid materials',
        details: [
          'When done, there will be a liquid part and solid part',
          'Use strainer and pour all contents through strainer into second jar',
          'The liquid part is what you want (FPJ)',
          'Strainer catches all solids, leaving just FPJ in your jar',
          'May take a while to strain - can leave for hours or even a day',
        ],
        tips: [
          'Be patient with straining - let gravity do the work',
          'The liquid FPJ is the valuable end product',
        ],
      ),
      
      // Storage Phase
      const GuideStep(
        phase: 'Storage',
        order: 9,
        title: 'Store Final FPJ',
        description: 'Properly store the fermented plant juice',
        details: [
          'Keep final FPJ with breathable lid',
          'Store in cool, dark, dry place',
          'Label with date and contents',
          'Can be stored for several months',
        ],
        tips: [
          'Breathable lid prevents pressure buildup',
          'Cool, dark storage preserves quality',
        ],
      ),
    ];
  }

  /// Generate FFJ steps following the correct procedure
  static List<GuideStep> _generateFFJSteps(List<Ingredient> ingredients, double totalWeight) {
    return [
      // Material Preparation Phase
      const GuideStep(
        phase: 'Material Preparation',
        order: 1,
        title: 'Prepare the Fruit',
        description: 'Select and prepare fruits for fermentation',
        details: [
          'Prepare the fruit, either picked or fallen',
          'Use grapes only for grapes and citrus only for citrus',
          'These fruits are not good when used on other crops due to their cold and sour characteristics',
          'Choose ripe, sweet fruits for best results',
          'Remove any damaged or rotten parts',
        ],
        tips: [
          'Grapes and citrus have specific characteristics that affect other crops',
          'Use only healthy, disease-free fruits',
        ],
      ),
      
      // Weighing Phase
      const GuideStep(
        phase: 'Weighing',
        order: 2,
        title: 'Weigh Fruit and Sugar',
        description: 'Measure equal parts of fruit and brown sugar',
        details: [
          'Weigh the prepared fruit',
          'Weigh equal parts brown sugar (1:1 ratio)',
          'Use a clean, accurate scale',
          'Record the weights for reference',
        ],
        tips: [
          'Equal weight ratio ensures proper fermentation',
          'Brown sugar provides food for beneficial microorganisms',
        ],
      ),
      
      // Preparation Phase
      const GuideStep(
        phase: 'Preparation',
        order: 3,
        title: 'Dice Up the Fruit Small',
        description: 'Cut fruits into small pieces for better fermentation',
        details: [
          'Dice up the fruit small',
          'Remove seeds and hard parts',
          'Ensure uniform size for even fermentation',
          'Work quickly to preserve essential substances',
        ],
        tips: [
          'Smaller pieces allow better sugar penetration',
          'Work quickly to prevent loss of beneficial microbes',
        ],
      ),
      
      // Mixing Phase
      const GuideStep(
        phase: 'Mixing',
        order: 4,
        title: 'Add Fruit and Sugar to Container',
        description: 'Combine fruit with brown sugar quickly',
        details: [
          'Add the fruit material to large mixing container',
          'Add the brown sugar immediately',
          'Work quickly to not lose essential substances and microbes',
          'Essential substances are released when fruit is chopped',
        ],
        tips: [
          'Speed is important to preserve beneficial microorganisms',
          'Use a container large enough for mixing',
        ],
      ),
      
      const GuideStep(
        phase: 'Mixing',
        order: 5,
        title: 'Mix and Stir Thoroughly',
        description: 'Mix all ingredients ensuring complete sugar coverage',
        details: [
          'Mix it all and stir (okay to be rough but not trying to smash it)',
          'Make sure every inch of fruit surface area is covered in sugar',
          'It will start to feel wet as sugar draws out moisture',
          'Ensure even distribution throughout the mixture',
        ],
        tips: [
          'Complete sugar coverage prevents spoilage',
          'The mixture should feel wet and sticky',
        ],
      ),
      
      // Fermentation Setup
      const GuideStep(
        phase: 'Fermentation Setup',
        order: 6,
        title: 'Put in Jar with Porous Lid',
        description: 'Transfer mixture to fermentation jar with proper covering',
        details: [
          'Put mixture in jar (ideally about 3/4 full)',
          'Use a porous lid on top (not airtight)',
          'End with a cap of brown sugar covering everything entirely',
          'Ensure sugar covers every visible inch of the mixture',
        ],
        tips: [
          '3/4 full allows space for fermentation gases',
          'Porous lid allows air circulation while preventing contamination',
          'Sugar cap acts as a protective barrier',
        ],
      ),
      
      // Fermentation Phase
      const GuideStep(
        phase: 'Fermentation',
        order: 7,
        title: 'Monitor Fermentation Process',
        description: 'Watch for fermentation completion based on temperature',
        details: [
          'Depending on temperature, this will take 3-10 days',
          'Shorter time in hotter temperatures',
          'Longer time in cooler temperatures',
          'Watch for liquid separation from solid parts',
        ],
        tips: [
          'Temperature directly affects fermentation speed',
          'Liquid separation indicates fermentation is complete',
        ],
      ),
      
      // Harvesting Phase
      const GuideStep(
        phase: 'Harvesting',
        order: 8,
        title: 'Strain the Fermented Juice',
        description: 'Separate liquid FFJ from solid materials',
        details: [
          'When done, there will be a liquid part and solid part',
          'Use strainer and pour all contents through strainer into second jar',
          'The liquid part is what you want (FFJ)',
          'Strainer catches all solids, leaving just FFJ in your jar',
          'May take a while to strain - can leave for hours or even a day',
        ],
        tips: [
          'Be patient with straining - let gravity do the work',
          'The liquid FFJ is the valuable end product',
        ],
      ),
      
      // Storage Phase
      const GuideStep(
        phase: 'Storage',
        order: 9,
        title: 'Store Final FFJ',
        description: 'Properly store the fermented fruit juice',
        details: [
          'Keep final FFJ with breathable lid',
          'Store in cool, dark, dry place',
          'Label with date and contents',
          'Can be stored for several months',
        ],
        tips: [
          'Breathable lid prevents pressure buildup',
          'Cool, dark storage preserves quality',
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
    
    if (method == RecipeMethod.ffj) {
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
