import 'package:firebase_auth/firebase_auth.dart';
import '../models/ingredient.dart';
import '../repositories/ingredients_repo.dart';
import '../services/firestore_service.dart';

class IngredientSeeder {
  static final FirestoreService _firestoreService = FirestoreService();
  static final IngredientsRepo _ingredientsRepo = IngredientsRepo(_firestoreService);

  static List<Ingredient> getLocalIngredients() {
    final now = DateTime.now();
    
    return [
      // FRUITS FOR FFJ
      Ingredient(
        id: 'banana_ripe',
        name: 'Ripe Banana',
        category: 'Fruit',
        description: 'Sweet, ripe bananas are excellent for FFJ. High in potassium and natural sugars.',
        recommendedFor: ['tomato', 'pepper', 'eggplant', 'okra', 'cucumber'],
        precautions: ['Use only ripe, not overripe bananas', 'Avoid bananas with mold'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'papaya_ripe',
        name: 'Ripe Papaya',
        category: 'Fruit',
        description: 'Sweet papaya provides enzymes and natural sugars for fermentation.',
        recommendedFor: ['tomato', 'pepper', 'cucumber', 'squash'],
        precautions: ['Use fully ripe papaya', 'Remove seeds before processing'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'mango_ripe',
        name: 'Ripe Mango',
        category: 'Fruit',
        description: 'Sweet mangoes provide excellent natural sugars and nutrients for FFJ.',
        recommendedFor: ['tomato', 'pepper', 'eggplant', 'cucumber'],
        precautions: ['Use only sweet, ripe mangoes', 'Remove skin and pit'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'coconut_water',
        name: 'Coconut Water',
        category: 'Fruit',
        description: 'Natural electrolyte-rich liquid that enhances fermentation process.',
        recommendedFor: ['rice', 'corn', 'vegetables', 'herbs'],
        precautions: ['Use fresh coconut water', 'Avoid contaminated water'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'calamansi_ripe',
        name: 'Ripe Calamansi',
        category: 'Fruit',
        description: 'Small citrus fruit rich in vitamin C and natural acids.',
        recommendedFor: ['tomato', 'pepper', 'citrus trees'],
        precautions: ['Use ripe calamansi', 'Can be mixed with other fruits'],
        createdAt: now,
      ),
      
      // FLOWERS FOR FFJ
      Ingredient(
        id: 'sampaguita_flowers',
        name: 'Sampaguita Flowers',
        category: 'Flower',
        description: 'Fragrant flowers that add beneficial compounds to FFJ.',
        recommendedFor: ['ornamental plants', 'herbs', 'vegetables'],
        precautions: ['Use fresh, clean flowers', 'Avoid flowers treated with chemicals'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'gumamela_flowers',
        name: 'Gumamela Flowers',
        category: 'Flower',
        description: 'Large, colorful flowers rich in natural compounds.',
        recommendedFor: ['ornamental plants', 'herbs'],
        precautions: ['Use fresh flowers', 'Remove green parts'],
        createdAt: now,
      ),
      
      // PLANT MATERIALS FOR FPJ
      Ingredient(
        id: 'moringa_leaves',
        name: 'Moringa Leaves',
        category: 'Plant',
        description: 'Highly nutritious leaves rich in vitamins and minerals. Excellent for FPJ.',
        recommendedFor: ['tomato', 'pepper', 'leafy vegetables', 'herbs'],
        precautions: ['Use young, tender leaves', 'Harvest in early morning'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'kamote_tops',
        name: 'Kamote Tops (Sweet Potato Leaves)',
        category: 'Plant',
        description: 'Fast-growing young shoots and leaves, excellent for FPJ fermentation.',
        recommendedFor: ['leafy vegetables', 'herbs', 'tomato', 'pepper'],
        precautions: ['Use young, tender shoots', 'Harvest before flowering'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'kangkong_leaves',
        name: 'Kangkong Leaves',
        category: 'Plant',
        description: 'Water spinach leaves, fast-growing and nutrient-rich.',
        recommendedFor: ['leafy vegetables', 'herbs', 'rice'],
        precautions: ['Use young leaves', 'Wash thoroughly'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'malunggay_leaves',
        name: 'Malunggay Leaves',
        category: 'Plant',
        description: 'Moringa leaves, highly nutritious and fast-growing.',
        recommendedFor: ['tomato', 'pepper', 'leafy vegetables', 'herbs'],
        precautions: ['Use young, tender leaves', 'Harvest in morning'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'alugbati_leaves',
        name: 'Alugbati Leaves',
        category: 'Plant',
        description: 'Vine spinach leaves, rich in nutrients and easy to grow.',
        recommendedFor: ['leafy vegetables', 'herbs', 'tomato'],
        precautions: ['Use young leaves', 'Wash well'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'young_coconut_shoots',
        name: 'Young Coconut Shoots',
        category: 'Plant',
        description: 'Tender coconut palm shoots, rich in growth hormones.',
        recommendedFor: ['trees', 'perennials', 'rice', 'corn'],
        precautions: ['Use only young, tender shoots', 'Harvest carefully'],
        createdAt: now,
      ),
      
      // WEEDS AND WILD PLANTS FOR FPJ
      Ingredient(
        id: 'makahiya_leaves',
        name: 'Makahiya Leaves',
        category: 'Weed',
        description: 'Sensitive plant leaves, rich in compounds beneficial for plants.',
        recommendedFor: ['vegetables', 'herbs', 'ornamental plants'],
        precautions: ['Use fresh leaves', 'Harvest in morning'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'purslane_leaves',
        name: 'Purslane Leaves',
        category: 'Weed',
        description: 'Common weed with succulent leaves, rich in nutrients.',
        recommendedFor: ['vegetables', 'herbs', 'leafy crops'],
        precautions: ['Use young leaves', 'Wash thoroughly'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'young_grass_tips',
        name: 'Young Grass Tips',
        category: 'Weed',
        description: 'Fast-growing grass tips, excellent source of growth hormones.',
        recommendedFor: ['rice', 'corn', 'grass crops'],
        precautions: ['Use only young, green tips', 'Avoid flowering grass'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'bamboo_shoots',
        name: 'Bamboo Shoots',
        category: 'Plant',
        description: 'Young bamboo shoots, rich in silica and growth compounds.',
        recommendedFor: ['trees', 'perennials', 'rice'],
        precautions: ['Use only young shoots', 'Process quickly'],
        createdAt: now,
      ),
      
      // SEAWEED AND MARINE MATERIALS
      Ingredient(
        id: 'seaweed_fresh',
        name: 'Fresh Seaweed',
        category: 'Marine',
        description: 'Marine algae rich in trace minerals and growth hormones.',
        recommendedFor: ['rice', 'corn', 'vegetables', 'trees'],
        precautions: ['Use fresh seaweed', 'Rinse with fresh water'],
        createdAt: now,
      ),
      
      // FISH AND ANIMAL MATERIALS
      Ingredient(
        id: 'fish_waste',
        name: 'Fish Waste',
        category: 'Animal',
        description: 'Fish scraps and waste, rich in nitrogen and phosphorus.',
        recommendedFor: ['vegetables', 'trees', 'perennials'],
        precautions: ['Use fresh waste', 'Handle with care', 'Keep covered'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'crab_shells',
        name: 'Crab Shells',
        category: 'Animal',
        description: 'Crab shells provide calcium and chitin for plant growth.',
        recommendedFor: ['tomato', 'pepper', 'fruit trees'],
        precautions: ['Clean shells thoroughly', 'Crush for better decomposition'],
        createdAt: now,
      ),
      
      // FERMENTATION AIDS
      Ingredient(
        id: 'brown_sugar',
        name: 'Brown Sugar',
        category: 'Fermentation Aid',
        description: 'Natural sweetener that feeds beneficial microorganisms during fermentation.',
        recommendedFor: ['all crops'],
        precautions: ['Use pure brown sugar', 'Avoid refined white sugar'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'molasses',
        name: 'Molasses',
        category: 'Fermentation Aid',
        description: 'Thick syrup rich in minerals and natural sugars for fermentation.',
        recommendedFor: ['all crops'],
        precautions: ['Use unsulfured molasses', 'Store in cool place'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'rice_wash',
        name: 'Rice Wash Water',
        category: 'Fermentation Aid',
        description: 'Water from washing rice, contains beneficial microorganisms.',
        recommendedFor: ['all crops'],
        precautions: ['Use fresh rice wash', 'Avoid soap contamination'],
        createdAt: now,
      ),
      
      // ADDITIONAL LOCAL INGREDIENTS
      Ingredient(
        id: 'ginger_root',
        name: 'Ginger Root',
        category: 'Root',
        description: 'Aromatic root with antimicrobial properties and nutrients.',
        recommendedFor: ['herbs', 'vegetables', 'ornamental plants'],
        precautions: ['Use fresh ginger', 'Slice thinly'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'turmeric_root',
        name: 'Turmeric Root',
        category: 'Root',
        description: 'Anti-inflammatory root with beneficial compounds for plants.',
        recommendedFor: ['herbs', 'vegetables', 'ornamental plants'],
        precautions: ['Use fresh turmeric', 'Can stain surfaces'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'young_corn_husks',
        name: 'Young Corn Husks',
        category: 'Plant',
        description: 'Young corn plant material, rich in growth hormones.',
        recommendedFor: ['corn', 'rice', 'grasses'],
        precautions: ['Use young, green husks', 'Harvest before maturity'],
        createdAt: now,
      ),
      
      Ingredient(
        id: 'banana_peel',
        name: 'Banana Peel',
        category: 'Plant',
        description: 'Banana peels rich in potassium and other nutrients.',
        recommendedFor: ['tomato', 'pepper', 'fruit trees'],
        precautions: ['Use fresh peels', 'Cut into small pieces'],
        createdAt: now,
      ),
    ];
  }

  static Future<void> seedIngredients() async {
    try {
      final ingredients = getLocalIngredients();
      print('Seeding ${ingredients.length} local ingredients...');
      
      // Check if user is authenticated
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      print('Current user: ${user?.uid ?? 'Not authenticated'}');
      
      if (user == null) {
        throw Exception('User must be authenticated to seed ingredients');
      }
      
      await _ingredientsRepo.batchCreateIngredients(ingredients);
      
      print('Successfully seeded ingredient database!');
    } catch (e) {
      print('Error seeding ingredients: $e');
      rethrow;
    }
  }

  static Future<void> clearAllIngredients() async {
    try {
      final ingredients = await _ingredientsRepo.getAllIngredients();
      for (final ingredient in ingredients) {
        await _ingredientsRepo.deleteIngredient(ingredient.id);
      }
      print('Cleared all ingredients from database');
    } catch (e) {
      print('Error clearing ingredients: $e');
      rethrow;
    }
  }

  static Future<Map<String, int>> getIngredientStats() async {
    try {
      return await _ingredientsRepo.getIngredientStats();
    } catch (e) {
      print('Error getting ingredient stats: $e');
      return {'total': 0, 'categories': 0, 'crops': 0};
    }
  }
}
