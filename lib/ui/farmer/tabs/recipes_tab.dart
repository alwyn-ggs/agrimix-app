import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe.dart';
import '../../../repositories/recipes_repo.dart';
import '../../../theme/theme.dart';
import '../../../router.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recipes', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: 'Search by crop or ingredient',
                hintStyle: TextStyle(
                  color: NatureColors.mediumGray,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: NatureColors.mediumGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: NatureColors.mediumGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: (_) => (context as Element).markNeedsBuild(),
            ),
          ),
          const Divider(height: 1),
          
          // Recipe List with Standard Recipes
          Expanded(
            child: ListView(
              children: [
                // Standard Recipes Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                    border: Border(
                      bottom: BorderSide(
                        color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: NatureColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Standard Recipes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: NatureColors.darkGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NatureColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // FPJ Recipe
                _buildStandardRecipeCard(
                  context: context,
                  method: RecipeMethod.fpj,
                  title: '🌱 Fermented Plant Juice (FPJ)',
                  description: 'For general plant growth and development',
                  color: NatureColors.lightGreen,
                ),
                
                // FFJ Recipe
                _buildStandardRecipeCard(
                  context: context,
                  method: RecipeMethod.ffj,
                  title: '🍌 Fermented Fruit Juice (FFJ)',
                  description: 'For flowering and fruit development',
                  color: NatureColors.accentGreen,
                ),
                
                // Divider between standard and other recipes
                Container(
                  height: 1,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                
                // Other Recipes Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    'Other Recipes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NatureColors.darkGray,
                    ),
                  ),
                ),
                
                // Public user-shared recipes (non-standard)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _PublicRecipesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardRecipeCard({
    required BuildContext context,
    required RecipeMethod method,
    required String title,
    required String description,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          method == RecipeMethod.fpj ? Icons.eco : Icons.local_florist,
          color: NatureColors.pureWhite,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                method == RecipeMethod.fpj ? '7 days' : '7-10 days',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.star,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Standard Recipe',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () => _showRecipeDetails(context, method),
    );
  }

  void _showRecipeDetails(BuildContext context, RecipeMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          method == RecipeMethod.fpj 
            ? '🌱 Fermented Plant Juice (FPJ)' 
            : '🍌 Fermented Fruit Juice (FFJ)',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                method == RecipeMethod.fpj 
                  ? 'For general plant growth and development'
                  : 'For flowering and fruit development',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Materials Needed:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (method == RecipeMethod.fpj) ...[
                const Text('• 2 kg plant materials (kangkong, banana trunk, alugbati, sweet potato, bamboo shoot)'),
                const Text('• 1 kg molasses or brown sugar'),
                const Text('• Clean paper or cloth (cover)'),
                const Text('• Bucket'),
              ] else ...[
                const Text('• 1 kg ripe fruits (mango, avocado, papaya, banana, mature squash, watermelon)'),
                const Text('• 1 kg molasses or brown sugar'),
                const Text('• Bucket'),
                const Text('• Paper or cloth (cover)'),
              ],
              
              const SizedBox(height: 16),
              
              const Text(
                'Process:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (method == RecipeMethod.fpj) ...[
                const Text('1. Cut 2 kg of plants rich in growth hormone'),
                const Text('2. Mix with 1 kg molasses/brown sugar'),
                const Text('3. Cover with paper/cloth and place in cool/dark place'),
                const Text('4. Ferment for 7 days'),
                const Text('5. Extract the liquid - this is FPJ'),
              ] else ...[
                const Text('1. Peel and cut 1 kg ripe fruits'),
                const Text('2. Mix with 1 kg molasses/brown sugar'),
                const Text('3. Cover and place in cool/dark place'),
                const Text('4. Ferment for 7-10 days until mold appears'),
                const Text('5. Extract the liquid - this is FFJ'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}

class _PublicRecipesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipesRepo>();
    return StreamBuilder<List<Recipe>>(
      // Watch all to avoid index requirements; filter client-side
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final recipes = (snap.data ?? const <Recipe>[]) 
            .where((r) => r.visibility == RecipeVisibility.public && !r.isStandard)
            .toList();
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load recipes. Please try again.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (recipes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No shared recipes yet. Be the first to share!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: recipes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = recipes[index];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NatureColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: r.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          r.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu, color: NatureColors.mediumGray),
                        ),
                      )
                    : const Icon(Icons.restaurant_menu, color: NatureColors.mediumGray),
              ),
              title: Text(
                r.name,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.method == RecipeMethod.ffj
                          ? NatureColors.lightGreen.withAlpha((0.2 * 255).round())
                          : NatureColors.accentGreen.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r.method.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.method == RecipeMethod.ffj ? NatureColors.primaryGreen : NatureColors.darkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.cropTarget,
                      style: const TextStyle(fontSize: 12, color: NatureColors.darkGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.of(context).pushNamed(
                  Routes.recipeDetail,
                  arguments: {'id': r.id},
                );
              },
            );
          },
        );
      },
    );
  }
}