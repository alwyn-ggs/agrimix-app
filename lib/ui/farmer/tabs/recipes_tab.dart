import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe.dart';
import '../../../models/user.dart';
import '../../../repositories/recipes_repo.dart';
import '../../../repositories/users_repo.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/theme.dart';
import '../../../router.dart';
import '../../../utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/feedback_service.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('recipes'), style: const TextStyle(color: Colors.white)),
        backgroundColor: NatureColors.primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Enhanced Search Section
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NatureColors.pureWhite,
                  Color(0xFFFAFBFA),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NatureColors.textDark.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: NatureColors.primaryGreen.withValues(alpha: 0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: TextField(
              style: const TextStyle(
                color: NatureColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '🔍 Search by crop or ingredient',
                hintStyle: const TextStyle(
                  color: NatureColors.mediumGray,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: NatureColors.primaryGreen,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.search,
                    color: NatureColors.primaryGreen,
                    size: 24,
                  ),
                ),
              ),
              onChanged: (_) => (context as Element).markNeedsBuild(),
            ),
          ),
          
          // Recipe List with Standard Recipes
          Expanded(
            child: ListView(
              children: [
                // Enhanced Standard Recipes Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NatureColors.primaryGreen,
                        NatureColors.lightGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: NatureColors.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NatureColors.pureWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: NatureColors.pureWhite,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.t('standard_recipes'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: NatureColors.pureWhite,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.t('verified_organic'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.offWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const _StandardRecipesList(),
                
                const SizedBox(height: 24),
                
                // Enhanced Other Recipes Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NatureColors.lightGreen.withValues(alpha: 0.1),
                        NatureColors.primaryGreen.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NatureColors.lightGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NatureColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: NatureColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.t('community_recipes'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: NatureColors.darkGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.t('shared_by_farmers'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  // ignore: unused_element
  Widget _buildStandardRecipeCard({
    required BuildContext context,
    required RecipeMethod method,
    required String title,
    required String description,
    required Color color,
  }) {
    final t = AppLocalizations.of(context);
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
                t.t('standard_recipe'),
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
    final t = AppLocalizations.of(context);
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
                  ? t.t('general_plant_growth')
                  : t.t('flowering_fruit'),
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
            child: Text(t.t('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
            },
            child: Text(t.t('view_details')),
          ),
        ],
      ),
    );
  }
}

class _StandardRecipesList extends StatelessWidget {
  const _StandardRecipesList();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipesRepo>();
    final usersRepo = context.read<UsersRepo>();
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;
    return StreamBuilder<List<Recipe>>(
      // Stream all to avoid composite index requirement; filter client-side
      stream: repo.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final recipes = (snapshot.data ?? const <Recipe>[]) 
            .where((r) => r.isStandard)
            .toList();
        if (recipes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No standard recipes available yet.',
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
              currentUserId: uid,
              recipesRepo: repo,
              usersRepo: usersRepo,
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _useStandardRecipe(BuildContext context, Recipe standard, String uid) async {
    try {
      final repo = context.read<RecipesRepo>();
      final newId = FirebaseFirestore.instance.collection(Recipe.collectionPath).doc().id;
      final copy = Recipe(
        id: newId,
        ownerUid: uid,
        name: standard.name,
        description: standard.description,
        method: standard.method,
        cropTarget: standard.cropTarget,
        ingredients: standard.ingredients,
        steps: standard.steps,
        visibility: RecipeVisibility.private,
        isStandard: false,
        likes: 0,
        avgRating: 0.0,
        totalRatings: 0,
        imageUrls: standard.imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createRecipe(copy);
      FeedbackService().showSnack('Added to your Drafts. Edit and share when ready.');
    } catch (e) {
      FeedbackService().showSnack('Failed to use recipe: $e');
    }
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
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NatureColors.pureWhite,
            Color(0xFFFAFBFA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: NatureColors.textDark.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: NatureColors.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NatureColors.pureWhite,
                  Color(0xFFFAFBFA),
                ],
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).pushNamed(
                  Routes.recipeDetail,
                  arguments: {'id': recipe.id},
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with image and basic info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced thumbnail with gradient border
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NatureColors.primaryGreen,
                                NatureColors.lightGreen,
                              ],
                            ),
                          ),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: NatureColors.lightGray,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: NatureColors.textDark.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: recipe.imageUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.network(
                                      recipe.imageUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              NatureColors.lightGray,
                                              NatureColors.mediumGray,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(13),
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu,
                                          color: NatureColors.pureWhite,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          NatureColors.lightGray,
                                          NatureColors.mediumGray,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.restaurant_menu,
                                      color: NatureColors.pureWhite,
                                      size: 36,
                                    ),
                                  ),
                          ),
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
                              // Enhanced Author information
                              StreamBuilder<AppUser?>(
                                stream: usersRepo.watchUser(recipe.ownerUid),
                                builder: (context, userSnap) {
                                  final author = userSnap.data;
                                  final hasName = author != null && author.name.trim().isNotEmpty;
                                  final ownerUid = recipe.ownerUid;
                                  if (hasName) {
                                    _authorNameCache[ownerUid] = author.name;
                                  }
                                  final cachedName = _authorNameCache[ownerUid];
                                  final nameToShow = hasName ? author.name : (cachedName ?? '');
                                  if (nameToShow.trim().isEmpty) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: NatureColors.lightGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: NatureColors.lightGreen.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: NatureColors.primaryGreen,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 12,
                                            color: NatureColors.pureWhite,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'by $nameToShow',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: NatureColors.darkGray,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
                        if (!recipe.isStandard) ...[
                          StreamBuilder<List<Map<String, dynamic>>>(
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
                          ),
                          _buildEnhancedChip(Icons.favorite, '${recipe.likes}', Colors.red[400]!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Interactive rating and favorites section
                    if (!recipe.isStandard) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Rating section
                          Expanded(
                            child: _buildRatingSection(recipe),
                          ),
                          const SizedBox(width: 8),
                          // Favorites button (flexible to avoid overflow)
                          Flexible(
                            fit: FlexFit.loose,
                            child: _buildFavoritesButton(recipe),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Action buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 400;
                        if (recipe.isStandard) {
                          // For standard recipes, show a primary "Use Recipe" action
                          return Row(
                            children: [
                              Text(
                                'Updated: ${_formatDate(recipe.updatedAt)}',
                                style: const TextStyle(fontSize: 12, color: NatureColors.mediumGray),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => _useStandardRecipe(context, recipe),
                                icon: const Icon(Icons.library_add, size: 18),
                                label: const Text('Use Recipe'),
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
                        }
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
                                      label: Text(t.t('view_recipe')),
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
        ),
      ),
    );
  }

  Future<void> _useStandardRecipe(BuildContext context, Recipe standard) async {
    try {
      if (currentUserId == null) {
        FeedbackService().showSnack('Please sign in to use this recipe.');
        return;
      }
      final newId = FirebaseFirestore.instance.collection(Recipe.collectionPath).doc().id;
      final copy = Recipe(
        id: newId,
        ownerUid: currentUserId!,
        name: standard.name,
        description: standard.description,
        method: standard.method,
        cropTarget: standard.cropTarget,
        ingredients: standard.ingredients,
        steps: standard.steps,
        visibility: RecipeVisibility.private,
        isStandard: false,
        likes: 0,
        avgRating: 0.0,
        totalRatings: 0,
        imageUrls: standard.imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await recipesRepo.createRecipe(copy);
      FeedbackService().showSnack('Added to your Drafts. Edit and share when ready.');
    } catch (e) {
      FeedbackService().showSnack('Failed to use recipe: $e');
    }
  }

  Widget _buildEnhancedChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: NatureColors.pureWhite,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
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
                    margin: const EdgeInsets.only(right: 2),
                    child: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: isFilled ? Colors.amber[600] : Colors.grey[400],
                      size: 20,
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
            size: 16,
          ),
          label: Text(
            isFavorite ? 'Saved' : 'Save',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFavorite ? Colors.red[50] : Colors.grey[50],
            foregroundColor: isFavorite ? Colors.red[600] : Colors.grey[600],
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(0, 36),
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
      FeedbackService().showSnack('Recipe rated $rating star${rating > 1 ? 's' : ''}!');
    } catch (e) {
      // Show error feedback
      FeedbackService().showSnack('Failed to rate recipe: $e');
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
      FeedbackService().showSnack(
        isCurrentlyFavorite 
          ? 'Recipe removed from favorites!' 
          : 'Recipe saved to favorites!'
      );
    } catch (e) {
      // Show error feedback
      FeedbackService().showSnack('Failed to save recipe: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}