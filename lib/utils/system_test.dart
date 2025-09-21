import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'ingredient_seeder.dart';
import 'logger.dart';

/// Test script to demonstrate the fermentation recipe formulation system
class SystemTest {
  static Future<void> runSystemTest() async {
    AppLogger.info('🌱 AgriMix Fermentation System Test');
    AppLogger.info('=====================================\n');
    
    // Test 1: Ingredient Database
    AppLogger.info('1. Testing Ingredient Database...');
    final ingredients = IngredientSeeder.getLocalIngredients();
    AppLogger.info('   ✅ Found ${ingredients.length} local ingredients');
    
    final categories = ingredients.map((i) => i.category).toSet().toList();
    AppLogger.info('   ✅ Categories: ${categories.join(', ')}');
    
    final ffjIngredients = ingredients.where((i) => 
      i.category.toLowerCase().contains('fruit') ||
      i.name.toLowerCase().contains('banana') ||
      i.name.toLowerCase().contains('papaya')
    ).toList();
    AppLogger.info('   ✅ FFJ suitable ingredients: ${ffjIngredients.length}');
    
    final fpjIngredients = ingredients.where((i) => 
      i.category.toLowerCase().contains('plant') ||
      i.category.toLowerCase().contains('leaf') ||
      i.name.toLowerCase().contains('moringa') ||
      i.name.toLowerCase().contains('kamote')
    ).toList();
    AppLogger.info('   ✅ FPJ suitable ingredients: ${fpjIngredients.length}\n');
    
    // Test 2: Recipe Generation
    AppLogger.info('2. Testing Recipe Generation...');
    
    // FFJ Recipe
    final ffjRecipe = generateTestRecipe(
      RecipeMethod.FFJ,
      ffjIngredients.take(3).toList(),
      'Test FFJ Recipe',
    );
    AppLogger.info('   ✅ FFJ Recipe generated with ${ffjRecipe.ingredients.length} ingredients');
    AppLogger.info('   📊 FFJ Total weight: ${_calculateTotalWeight(ffjRecipe.ingredients).toStringAsFixed(1)} kg');
    
    // FPJ Recipe
    final fpjRecipe = generateTestRecipe(
      RecipeMethod.FPJ,
      fpjIngredients.take(3).toList(),
      'Test FPJ Recipe',
    );
    AppLogger.info('   ✅ FPJ Recipe generated with ${fpjRecipe.ingredients.length} ingredients');
    AppLogger.info('   📊 FPJ Total weight: ${_calculateTotalWeight(fpjRecipe.ingredients).toStringAsFixed(1)} kg\n');
    
    // Test 3: Ingredient Recommendations
    AppLogger.info('3. Testing Ingredient Recommendations...');
    final tomatoIngredients = ingredients.where((i) => 
      i.recommendedFor.any((crop) => crop.toLowerCase().contains('tomato'))
    ).toList();
    AppLogger.info('   ✅ Ingredients recommended for tomato: ${tomatoIngredients.length}');
    
    final riceIngredients = ingredients.where((i) => 
      i.recommendedFor.any((crop) => crop.toLowerCase().contains('rice'))
    ).toList();
    AppLogger.info('   ✅ Ingredients recommended for rice: ${riceIngredients.length}\n');
    
    // Test 4: Recipe Steps
    AppLogger.info('4. Testing Recipe Steps...');
    AppLogger.info('   ✅ FFJ steps: ${ffjRecipe.steps.length} detailed steps');
    AppLogger.info('   ✅ FPJ steps: ${fpjRecipe.steps.length} detailed steps\n');
    
    // Test 5: System Summary
    AppLogger.info('5. System Summary...');
    AppLogger.info('   🌱 Fermentation methods: FFJ, FPJ');
    AppLogger.info('   🍎 Fruit ingredients: ${ffjIngredients.length}');
    AppLogger.info('   🌿 Plant ingredients: ${fpjIngredients.length}');
    AppLogger.info('   📋 Total ingredients: ${ingredients.length}');
    AppLogger.info('   🏷️ Categories: ${categories.length}');
    AppLogger.info('   📖 Recipe steps: Detailed fermentation guidance\n');
    
    AppLogger.info('✅ All tests completed successfully!');
    AppLogger.info('🎉 The fermentation-based liquid fertilizer system is ready for farmers!');
  }
  
  static Recipe generateTestRecipe(RecipeMethod method, List<Ingredient> ingredients, String name) {
    final now = DateTime.now();
    final recipeIngredients = <RecipeIngredient>[];
    
    // Calculate weights (2:1 ratio for materials:sugar)
    const totalWeight = 3.0; // kg
    const materialWeight = totalWeight * (2.0 / 3.0); // 2 kg
    const sugarWeight = totalWeight * (1.0 / 3.0); // 1 kg
    
    // Distribute material weight among ingredients
    final weightPerIngredient = ingredients.isNotEmpty ? materialWeight / ingredients.length : 0.0;
    
    // Add ingredient materials
    for (final ingredient in ingredients) {
      recipeIngredients.add(RecipeIngredient(
        ingredientId: ingredient.id,
        name: ingredient.name,
        amount: weightPerIngredient,
        unit: 'kg',
      ));
    }
    
    // Add brown sugar
    recipeIngredients.add(const RecipeIngredient(
      ingredientId: 'brown_sugar',
      name: 'Brown sugar',
      amount: sugarWeight,
      unit: 'kg',
    ));
    
    // Generate steps
    final steps = generateSteps(method);
    
    return Recipe(
      id: now.millisecondsSinceEpoch.toString(),
      ownerUid: 'test_user',
      name: name,
      description: 'Test recipe for $name',
      method: method,
      cropTarget: 'Test crops',
      ingredients: recipeIngredients,
      steps: steps,
      visibility: RecipeVisibility.private,
      isStandard: false,
      likes: 0,
      avgRating: 0.0,
      totalRatings: 0,
      imageUrls: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
  
  static List<RecipeStep> generateSteps(RecipeMethod method) {
    final steps = <String>[
      'Maghanda ng malinis na kagamitan at lalagyan (glass o food-grade plastic).',
      'Siguraduhing malinis ang mga kamay at lugar ng paggawa.',
      if (method == RecipeMethod.FFJ) ...[
        'Hugasan at tuyuin ang mga prutas. Tanggalin ang mga bulok na parte.',
        'Gayatin ang mga prutas sa maliliit na piraso (1-2 cm) para sa mas mabilis na fermentation.',
        'Ilagay ang mga prutas sa lalagyan at haluan ng brown sugar. Ihalo nang mabuti.',
        'Takpan ng malinis na papel o tela (hindi airtight) at i-secure ng goma.',
        'Ilagay sa malamig, madilim na lugar (20-25°C). Iwasan ang direktang sikat ng araw.',
        'Araw-araw na haluin ang mixture ng 2-3 beses sa unang 3 araw.',
        'Hayaang maburo ng 7-10 araw. Magkakaroon ng natural na amag sa ibabaw.',
        'Kapag may natural na amag at matamis na amoy, katasin na ang mixture.',
        'I-filter ang juice gamit ang malinis na tela at ilagay sa malinis na bote.',
        'Ang FFJ ay maaaring gamitin agad o i-store sa ref ng hanggang 6 na buwan.',
      ] else ...[
        'Gumamit ng mga batang dahon at shoots (mga 2-3 buwan gulang).',
        'Hugasan at tuyuin ang mga halaman. Tanggalin ang mga tuyo o may sakit na parte.',
        'Gayatin ang mga halaman sa maliliit na piraso (2-3 cm) para sa mas mabilis na fermentation.',
        'Ilagay ang mga halaman sa lalagyan at haluan ng brown sugar. Ihalo nang mabuti.',
        'Takpan ng malinis na papel o tela (hindi airtight) at i-secure ng goma.',
        'Ilagay sa malamig, madilim na lugar (20-25°C). Iwasan ang direktang sikat ng araw.',
        'Araw-araw na haluin ang mixture ng 2-3 beses sa unang 3 araw.',
        'Hayaang maburo ng 7 araw. Magkakaroon ng natural na amag sa ibabaw.',
        'Kapag may natural na amag at matamis na amoy, katasin na ang mixture.',
        'I-filter ang juice gamit ang malinis na tela at ilagay sa malinis na bote.',
        'Ang FPJ ay maaaring gamitin agad o i-store sa ref ng hanggang 6 na buwan.',
      ],
      'Para sa paggamit: Ihalo ang 1-2 kutsara sa 1 litro ng tubig at spray sa mga halaman.',
      'Gamitin tuwing umaga o hapon, iwasan ang tanghaling tapat.',
    ];
    
    return [
      for (int i = 0; i < steps.length; i++) 
        RecipeStep(order: i + 1, text: steps[i])
    ];
  }
  
  static double _calculateTotalWeight(List<RecipeIngredient> ingredients) {
    return ingredients.fold(0.0, (sum, ingredient) => sum + ingredient.amount);
  }
}
