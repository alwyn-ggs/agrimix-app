import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe.dart';
import '../../../models/user.dart';
import '../../../repositories/recipes_repo.dart';
import '../../../repositories/users_repo.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/theme.dart';
import '../../../router.dart';
import '../../../utils/logger.dart';

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

  Widget _buildLiveRatingChip() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipesRepo.watchRecipeRatingsRaw(recipe.id),
      builder: (context, snapshot) {
        double avg = recipe.avgRating;
        int count = recipe.totalRatings;
        if (snapshot.hasData) {
          final ratings = snapshot.data!;
          if (ratings.isNotEmpty) {
            final total = ratings
                .map((m) => (m['rating'] as num?)?.toDouble() ?? 0.0)
                .fold<double>(0.0, (a, b) => a + b);
            count = ratings.length;
            avg = total / count;
          }
        }
        return _buildEnhancedChip(
          Icons.star,
          '${avg.toStringAsFixed(1)} ($count)',
          Colors.amber[700]!,
        );
      },
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
    final usersRepo = context.read<UsersRepo>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentAppUser;
    
    return StreamBuilder<List<Recipe>>(
      // Query all recipes and filter client-side to avoid composite index issues
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Get all recipes and filter for public, non-standard recipes
        final allRecipes = snap.data ?? const <Recipe>[];
        final recipes = allRecipes.where((r) => 
          r.visibility == RecipeVisibility.public && !r.isStandard
        ).toList();
        
        if (snap.hasError) {
          AppLogger.error('Error in recipe stream: ${snap.error}');
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Failed to load recipes. Please try again.',
              style: TextStyle(color: Colors.red),
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
            return _InteractiveRecipeCard(
              recipe: r,
              currentUserId: currentUser?.uid,
              recipesRepo: repo,
              usersRepo: usersRepo,
            );
          },
        );
      },
    );
  }
}

class _InteractiveRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String? currentUserId;
  final RecipesRepo recipesRepo;
  final UsersRepo usersRepo;

  const _InteractiveRecipeCard({
    required this.recipe,
    required this.currentUserId,
    required this.recipesRepo,
    required this.usersRepo,
  });

  // Cache author names to avoid flicker when stream rebuilds
  static final Map<String, String> _authorNameCache = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              NatureColors.lightGray.withAlpha((0.1 * 255).round()),
            ],
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushNamed(
              Routes.recipeDetail,
              arguments: {'id': recipe.id},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced thumbnail
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: NatureColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: recipe.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                recipe.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu, color: NatureColors.mediumGray, size: 32),
                              ),
                            )
                          : const Icon(Icons.restaurant_menu, color: NatureColors.mediumGray, size: 32),
                    ),
                    const SizedBox(width: 16),
                    // Title and author info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: NatureColors.darkGreen,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildVisibilityChip(recipe),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Author information
                          StreamBuilder<AppUser?>(
                            stream: usersRepo.watchUser(recipe.ownerUid),
                            builder: (context, userSnap) {
                              final author = userSnap.data;
                              final hasName = author != null && author.name.trim().isNotEmpty;
                              final ownerUid = recipe.ownerUid;
                              if (hasName) {
                                _authorNameCache[ownerUid] = author!.name;
                              }
                              final cachedName = _authorNameCache[ownerUid];
                              final nameToShow = hasName ? author!.name : (cachedName ?? '');
                              if (nameToShow.trim().isEmpty) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: NatureColors.primaryGreen,
                                    child: Icon(Icons.person, size: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'by: $nameToShow',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: NatureColors.darkGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (recipe.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              recipe.description,
                              style: const TextStyle(fontSize: 14, color: NatureColors.darkGray),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Enhanced info chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildEnhancedChip(Icons.local_dining, recipe.method.name.toUpperCase(), NatureColors.primaryGreen),
                    _buildEnhancedChip(Icons.eco, recipe.cropTarget, NatureColors.lightGreen),
                    _buildLiveRatingChip(),
                    _buildEnhancedChip(Icons.favorite, '${recipe.likes}', Colors.red[400]!),
                  ],
                ),
                const SizedBox(height: 16),
                // Interactive rating and favorites section
                Row(
                  children: [
                    // Rating section
                    Expanded(
                      child: _buildRatingSection(recipe),
                    ),
                    const SizedBox(width: 16),
                    // Favorites button
                    _buildFavoritesButton(recipe),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 400;
                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Updated: ${_formatDate(recipe.updatedAt)}',
                            style: const TextStyle(fontSize: 12, color: NatureColors.mediumGray),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      Routes.recipeDetail,
                                      arguments: {'id': recipe.id},
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('View Recipe'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NatureColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Text(
                          'Updated: ${_formatDate(recipe.updatedAt)}',
                          style: const TextStyle(fontSize: 12, color: NatureColors.mediumGray),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              Routes.recipeDetail,
                              arguments: {'id': recipe.id},
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('View Recipe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NatureColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.3 * 255).round()), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityChip(Recipe recipe) {
    final isPublic = recipe.visibility == RecipeVisibility.public;
    return _buildBadge(isPublic ? 'PUBLIC' : 'PRIVATE', isPublic ? Colors.green[800]! : Colors.grey[700]!, isPublic ? Colors.green[100]! : Colors.grey[200]!);
  }

  Widget _buildBadge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildRatingSection(Recipe recipe) {
    if (currentUserId == null || currentUserId == recipe.ownerUid) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<double?>(
      future: recipesRepo.getRecipeRating(recipe.id, currentUserId!),
      builder: (context, snapshot) {
        final userRating = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate this recipe:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NatureColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFilled = userRating != null && starIndex <= userRating;
                return GestureDetector(
                  onTap: () => _rateRecipe(context, recipe, starIndex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: isFilled ? Colors.amber[600] : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavoritesButton(Recipe recipe) {
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: recipesRepo.watchIsFavorite(
        userId: currentUserId!,
        recipeId: recipe.id,
      ),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return ElevatedButton.icon(
          onPressed: () => _toggleFavorite(context, recipe),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 18,
          ),
          label: Text(isFavorite ? 'Saved' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFavorite ? Colors.red[50] : Colors.grey[50],
            foregroundColor: isFavorite ? Colors.red[600] : Colors.grey[600],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isFavorite ? Colors.red[200]! : Colors.grey[300]!,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _rateRecipe(BuildContext context, Recipe recipe, int rating) async {
    try {
      await recipesRepo.rateRecipe(
        recipe.id,
        currentUserId!,
        rating.toDouble(),
      );
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe rated $rating star${rating > 1 ? 's' : ''}!'),
          backgroundColor: NatureColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rate recipe: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(BuildContext context, Recipe recipe) async {
    try {
      // Get current favorite status before toggling
      final isCurrentlyFavorite = await recipesRepo.watchIsFavorite(
        userId: currentUserId!,
        recipeId: recipe.id,
      ).first;
      
      await recipesRepo.toggleFavorite(
        userId: currentUserId!,
        recipeId: recipe.id,
      );
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite 
              ? 'Recipe removed from favorites!' 
              : 'Recipe saved to favorites!'
          ),
          backgroundColor: NatureColors.primaryGreen,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Favorites',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to My Recipes tab with Favorites selected
              // This would require access to the parent dashboard to switch tabs
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to "My Recipes" tab to view your favorites'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recipe: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
