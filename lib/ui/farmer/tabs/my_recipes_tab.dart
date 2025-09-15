import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../models/recipe.dart';
import '../../../repositories/recipes_repo.dart';

class MyRecipesTab extends StatefulWidget {
  const MyRecipesTab({super.key});

  @override
  State<MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends State<MyRecipesTab> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  RecipeMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final userId = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Recipes', style: TextStyle(color: Colors.white)),
        backgroundColor: NatureColors.primaryGreen,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Drafts'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.person), text: 'My Created'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDraftsTab(userId, recipeProvider),
          _buildFavoritesTab(userId, recipeProvider),
          _buildHistoryTab(userId, recipeProvider),
          _buildMyCreatedTab(userId, recipeProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(Routes.formulateRecipe),
        icon: const Icon(Icons.add),
        label: const Text('Create Recipe'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDraftsTab(String userId, RecipeProvider recipeProvider) {
    final recipesRepo = context.read<RecipesRepo>();
    if (userId.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_note,
        title: 'No Draft Recipes',
        subtitle: 'Please log in to see your drafts',
      );
    }
    return StreamBuilder<List<Recipe>>(
      stream: recipesRepo.watchRecipes(
        ownerUid: userId,
        visibility: RecipeVisibility.private,
        isStandard: false,
        orderByCreatedAt: false,
      ),
      initialData: const <Recipe>[],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Fallback to one-time load (e.g., if Firestore index/orderBy error)
          return FutureBuilder<List<Recipe>>(
            future: recipesRepo.getRecipes(
              ownerUid: userId,
              visibility: RecipeVisibility.private,
              isStandard: false,
            ),
            builder: (context, fbSnap) {
              if (fbSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = (fbSnap.data ?? const <Recipe>[]);
              if (list.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.edit_note,
                  title: 'No Draft Recipes',
                  subtitle: 'Start creating a new recipe to see your drafts here',
                );
              }
              return _buildRecipeList(list, 'Draft Recipes');
            },
          );
        }

        final drafts = List<Recipe>.from(snapshot.data ?? const <Recipe>[]);
        drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (drafts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.edit_note,
            title: 'No Draft Recipes',
            subtitle: 'Start creating a new recipe to see your drafts here',
          );
        }

        return _buildRecipeList(drafts, 'Draft Recipes');
      },
    );
  }

  Widget _buildFavoritesTab(String userId, RecipeProvider recipeProvider) {
    return FutureBuilder<List<Recipe>>(
      future: _getFavoriteRecipes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Favorite Recipes',
            subtitle: 'Like recipes to see them in your favorites',
            actionText: 'Browse Recipes',
            onAction: () => Navigator.of(context).pushNamed(Routes.recipes),
          );
        }

        final favorites = snapshot.data!;
        return _buildRecipeList(favorites, 'Favorite Recipes');
      },
    );
  }

  Widget _buildHistoryTab(String userId, RecipeProvider recipeProvider) {
    return FutureBuilder<List<Recipe>>(
      future: _getRecentlyViewedRecipes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Recent Activity',
            subtitle: 'View recipes to see your history here',
            actionText: 'Browse Recipes',
            onAction: () => Navigator.of(context).pushNamed(Routes.recipes),
          );
        }

        final history = snapshot.data!;
        return _buildRecipeList(history, 'Recently Viewed');
      },
    );
  }

  Widget _buildMyCreatedTab(String userId, RecipeProvider recipeProvider) {
    return FutureBuilder<List<Recipe>>(
      future: _getMyCreatedRecipes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.create,
            title: 'No Created Recipes',
            subtitle: 'Create your first recipe to see it here',
          );
        }

        final created = snapshot.data!;
        return _buildRecipeList(created, 'My Created Recipes');
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: NatureColors.mediumGray,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: NatureColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NatureColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes, String title) {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NatureColors.lightGreen.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: NatureColors.lightGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: NatureColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
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
                child: Text(
                  '${recipes.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search recipes...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<RecipeMethod?>(
                value: _selectedMethod,
                hint: const Text('Method'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: RecipeMethod.FFJ, child: Text('FFJ')),
                  DropdownMenuItem(value: RecipeMethod.FPJ, child: Text('FPJ')),
                ],
                onChanged: (value) => setState(() => _selectedMethod = value),
              ),
            ],
          ),
        ),
        
        // Recipe List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _buildRecipeCard(recipe);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          Routes.recipeDetail,
          arguments: {'id': recipe.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe image placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: NatureColors.lightGray,
                    ),
                    child: recipe.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              recipe.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                            ),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NatureColors.darkGreen,
                          ),
                        ),
                        if (recipe.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            recipe.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: NatureColors.darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: recipe.method == RecipeMethod.FFJ 
                                    ? NatureColors.lightGreen.withOpacity(0.2)
                                    : NatureColors.accentGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                recipe.method.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: recipe.method == RecipeMethod.FFJ 
                                      ? NatureColors.primaryGreen
                                      : NatureColors.darkGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recipe.cropTarget,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: NatureColors.darkGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Recipe status indicators
                  Column(
                    children: [
                      if (recipe.steps.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timeline,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${recipe.steps.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (recipe.isStandard)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NatureColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Standard',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: NatureColors.primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        recipe.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NatureColors.darkGray,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${recipe.totalRatings})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: NatureColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(recipe.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: NatureColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: NatureColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant_menu,
        color: NatureColors.mediumGray,
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Data fetching methods
  Future<List<Recipe>> _getDraftRecipes(String userId) async {
    final recipesRepo = context.read<RecipesRepo>();
    try {
      final mine = await recipesRepo.getUserRecipes(userId);
      return mine.where((recipe) =>
        recipe.visibility == RecipeVisibility.private &&
        !recipe.isStandard
      ).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> _getFavoriteRecipes(String userId) async {
    final recipesRepo = context.read<RecipesRepo>();
    try {
      final favoriteIds = await recipesRepo.getFavoriteIds(userId: userId);
      final allRecipes = await recipesRepo.getAllRecipes();
      return allRecipes.where((recipe) => favoriteIds.contains(recipe.id)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> _getRecentlyViewedRecipes(String userId) async {
    // This would need to be implemented with a viewing history system
    // For now, return empty list
    return [];
  }

  Future<List<Recipe>> _getMyCreatedRecipes(String userId) async {
    final recipesRepo = context.read<RecipesRepo>();
    try {
      final allRecipes = await recipesRepo.getAllRecipes();
      return allRecipes.where((recipe) => 
        recipe.ownerUid == userId && 
        recipe.visibility == RecipeVisibility.public
      ).toList();
    } catch (e) {
      return [];
    }
  }
}
