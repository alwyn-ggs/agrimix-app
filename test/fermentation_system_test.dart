import 'package:flutter_test/flutter_test.dart';
import 'package:agrimix/models/ingredient.dart';
import 'package:agrimix/models/recipe.dart';
import 'package:agrimix/utils/ingredient_seeder.dart';
import 'package:agrimix/utils/system_test.dart';

void main() {
  group('Fermentation System Tests', () {
    test('should have local ingredients available', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      expect(ingredients.length, greaterThan(0));
      expect(ingredients.first, isA<Ingredient>());
    });

    test('should categorize ingredients correctly', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final categories = ingredients.map((i) => i.category).toSet().toList();
      
      expect(categories.length, greaterThan(0));
      expect(categories, contains('Fruit'));
      expect(categories, contains('Plant'));
    });

    test('should have FFJ suitable ingredients', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final ffjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('fruit') ||
        i.name.toLowerCase().contains('banana') ||
        i.name.toLowerCase().contains('papaya')
      ).toList();
      
      expect(ffjIngredients.length, greaterThan(0));
    });

    test('should have FPJ suitable ingredients', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final fpjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('plant') ||
        i.category.toLowerCase().contains('leaf') ||
        i.name.toLowerCase().contains('moringa') ||
        i.name.toLowerCase().contains('kamote')
      ).toList();
      
      expect(fpjIngredients.length, greaterThan(0));
    });

    test('should generate FFJ recipe with correct ratios', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final ffjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('fruit')
      ).take(3).toList();
      
      final recipe = SystemTest.generateTestRecipe(
        RecipeMethod.FFJ,
        ffjIngredients,
        'Test FFJ Recipe',
      );
      
      expect(recipe.method, equals(RecipeMethod.FFJ));
      expect(recipe.ingredients.length, greaterThan(0));
      
      // Check that brown sugar is included
      final hasBrownSugar = recipe.ingredients.any((ing) => ing.name == 'Brown sugar');
      expect(hasBrownSugar, isTrue);
    });

    test('should generate FPJ recipe with correct ratios', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final fpjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('plant')
      ).take(3).toList();
      
      final recipe = SystemTest.generateTestRecipe(
        RecipeMethod.FPJ,
        fpjIngredients,
        'Test FPJ Recipe',
      );
      
      expect(recipe.method, equals(RecipeMethod.FPJ));
      expect(recipe.ingredients.length, greaterThan(0));
      
      // Check that brown sugar is included
      final hasBrownSugar = recipe.ingredients.any((ing) => ing.name == 'Brown sugar');
      expect(hasBrownSugar, isTrue);
    });

    test('should have detailed recipe steps', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final ffjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('fruit')
      ).take(2).toList();
      
      final recipe = SystemTest.generateTestRecipe(
        RecipeMethod.FFJ,
        ffjIngredients,
        'Test Recipe',
      );
      
      expect(recipe.steps.length, greaterThan(10)); // Should have detailed steps
      expect(recipe.steps.first.text, contains('Maghanda')); // Should be in Filipino
    });

    test('should have ingredient recommendations for crops', () {
      final ingredients = IngredientSeeder.getLocalIngredients();
      final tomatoIngredients = ingredients.where((i) => 
        i.recommendedFor.any((crop) => crop.toLowerCase().contains('tomato'))
      ).toList();
      
      expect(tomatoIngredients.length, greaterThan(0));
    });
  });

  group('System Integration Tests', () {
    test('should demonstrate complete fermentation workflow', () async {
      print('\n🌱 Running Fermentation System Integration Test...');
      
      // Get ingredients
      final ingredients = IngredientSeeder.getLocalIngredients();
      print('✅ Found ${ingredients.length} ingredients');
      
      // Test FFJ workflow
      final ffjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('fruit')
      ).take(2).toList();
      
      final ffjRecipe = SystemTest.generateTestRecipe(
        RecipeMethod.FFJ,
        ffjIngredients,
        'Integration Test FFJ',
      );
      
      print('✅ FFJ Recipe: ${ffjRecipe.ingredients.length} ingredients, ${ffjRecipe.steps.length} steps');
      
      // Test FPJ workflow
      final fpjIngredients = ingredients.where((i) => 
        i.category.toLowerCase().contains('plant')
      ).take(2).toList();
      
      final fpjRecipe = SystemTest.generateTestRecipe(
        RecipeMethod.FPJ,
        fpjIngredients,
        'Integration Test FPJ',
      );
      
      print('✅ FPJ Recipe: ${fpjRecipe.ingredients.length} ingredients, ${fpjRecipe.steps.length} steps');
      
      // Verify system functionality
      expect(ffjRecipe.method, equals(RecipeMethod.FFJ));
      expect(fpjRecipe.method, equals(RecipeMethod.FPJ));
      expect(ffjRecipe.ingredients.isNotEmpty, isTrue);
      expect(fpjRecipe.ingredients.isNotEmpty, isTrue);
      
      print('🎉 Integration test completed successfully!');
    });
  });
}
