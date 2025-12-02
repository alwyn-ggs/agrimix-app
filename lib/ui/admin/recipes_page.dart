import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';
import '../../router.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  RecipeMethod? _selectedMethod;
  // Removed: standard-only filter chip

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          // Tab Bar
          _buildTabBar(),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRecipesTab(),
                _buildStandardRecipesTab(),
                _buildFlaggedRecipesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: NatureColors.pureWhite,
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<RecipeMethod?>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Method',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<RecipeMethod?>(
                        value: null,
                        child: Text('All Methods'),
                      ),
                      ...RecipeMethod.values.map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (_tabController.index == 1)
                  FilledButton.icon(
                    onPressed: _createStandardRecipe,
                    style: FilledButton.styleFrom(
                      backgroundColor: NatureColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Standard'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createStandardRecipe() async {
    // Simple flow: open editor in create mode; after save, admin can toggle to Standard in edit.
    if (!mounted) return;
    Navigator.of(context).pushNamed(Routes.recipeEdit, arguments: {
      'mode': 'create',
      'forceStandard': true,
    });
  }

  Widget _buildTabBar() {
    return Container(
      color: NatureColors.pureWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: NatureColors.primaryGreen,
        unselectedLabelColor: NatureColors.mediumGray,
        indicatorColor: NatureColors.primaryGreen,
        tabs: const [
          Tab(text: 'All Recipes'),
          Tab(text: 'Standard'),
          Tab(text: 'Flagged'),
        ],
      ),
    );
  }

  Widget _buildAllRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Show loading state
        if (adminProvider.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NatureColors.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Loading recipes...',
                  style: TextStyle(
                    fontSize: 16,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
          );
        }

        // Show error state
        if (adminProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load recipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adminProvider.error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NatureColors.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Refresh the admin provider
                    adminProvider.refreshRecipes();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Sectioned view like user Recipes tab: Standard + Other
        final all = adminProvider.allRecipes;
        final standardRecipes = all.where((r) => r.isStandard).where(_matchesFilters).toList();
        // Farmer-shared public recipes for the Other Recipes section
        final otherRecipes = all
            .where((r) => !r.isStandard && r.visibility == RecipeVisibility.public)
            .where(_matchesFilters)
            .toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // Standard header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: NatureColors.pureWhite,
              child: Row(
                children: [
                  const Icon(Icons.star, color: NatureColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Standard Recipes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NatureColors.darkGray),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge('${standardRecipes.length}', Colors.white, NatureColors.primaryGreen),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (standardRecipes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No standard recipes', style: TextStyle(color: NatureColors.mediumGray)),
              )
            else
              ...standardRecipes.map(_buildRecipeCard),

            // Divider
            Container(height: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),

            // Other header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: NatureColors.pureWhite,
              child: const Text(
                'Other Recipes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NatureColors.darkGray),
              ),
            ),
            const SizedBox(height: 8),
            if (otherRecipes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No other recipes', style: TextStyle(color: NatureColors.mediumGray)),
              )
            else
              ...otherRecipes.map(_buildRecipeCard),

          ],
        );
      },
    );
  }

  // Removed Review Queue tab per requirements

  Widget _buildStandardRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Show loading state
        if (adminProvider.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NatureColors.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Loading recipes...',
                  style: TextStyle(
                    fontSize: 16,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
          );
        }

        // Show error state
        if (adminProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load recipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adminProvider.error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NatureColors.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    adminProvider.refreshRecipes();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final recipes = adminProvider.standardRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildFlaggedRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Show loading state
        if (adminProvider.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NatureColors.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Loading recipes...',
                  style: TextStyle(
                    fontSize: 16,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
          );
        }

        // Show error state
        if (adminProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load recipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adminProvider.error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NatureColors.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    adminProvider.refreshRecipes();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final recipes = adminProvider.flaggedRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    // Filter recipes based on search query and selected method
    final filteredRecipes = recipes.where(_matchesFilters).toList();

    if (filteredRecipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: NatureColors.lightGray),
            SizedBox(height: 16),
            Text(
              'No recipes found',
              style: TextStyle(
                fontSize: 16,
                color: NatureColors.darkGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filteredRecipes.length,
      itemBuilder: (context, index) => _buildRecipeCard(filteredRecipes[index]),
    );
  }

  // Shared filtering logic for All/Standard/Flagged lists
  bool _matchesFilters(Recipe recipe) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = recipe.name.toLowerCase().contains(query) ||
          recipe.description.toLowerCase().contains(query) ||
          recipe.ingredients.any((ing) => ing.name.toLowerCase().contains(query));
      if (!matchesSearch) return false;
    }
    if (_selectedMethod != null && recipe.method != _selectedMethod) {
      return false;
    }
    return true;
  }

  // Card renderer reused across lists and sections
  Widget _buildRecipeCard(Recipe recipe) {
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
                            if (recipe.isStandard) ...[
                              const SizedBox(width: 6),
                              _buildBadge('STANDARD', Colors.amber[800]!, Colors.amber[100]!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Author information
                        FutureBuilder<AppUser?>(
                          future: context.read<AdminProvider>().usersRepo.getUser(recipe.ownerUid),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final author = snapshot.data!;
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: NatureColors.primaryGreen,
                                    child: Text(
                                      author.name.isNotEmpty ? author.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'by ${author.name}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: NatureColors.darkGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
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
                  _buildEnhancedChip(Icons.star, '${recipe.avgRating.toStringAsFixed(1)} (${recipe.totalRatings})', Colors.amber[700]!),
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
                                onPressed: () => _viewRecipe(context, recipe),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmDelete(context, recipe),
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
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
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Updated: ${_formatDate(recipe.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: NatureColors.mediumGray),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _viewRecipe(context, recipe),
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
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, recipe),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  void _viewRecipe(BuildContext context, Recipe recipe) {
    Navigator.of(context).pushNamed(
      Routes.recipeDetail,
      arguments: {'id': recipe.id},
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  Widget _buildEnhancedChip(IconData icon, String text, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
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
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(Recipe recipe) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentAppUser;
        if (currentUser == null) return const SizedBox.shrink();

        return FutureBuilder<double?>(
          future: context.read<AdminProvider>().recipes.getRecipeRating(recipe.id, currentUser.uid),
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
                      onTap: () => _rateRecipe(recipe, starIndex),
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
      },
    );
  }

  Widget _buildFavoritesButton(Recipe recipe) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentAppUser;
        if (currentUser == null) return const SizedBox.shrink();

        return StreamBuilder<bool>(
          stream: context.read<AdminProvider>().recipes.watchIsFavorite(
            userId: currentUser.uid,
            recipeId: recipe.id,
          ),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            return ElevatedButton.icon(
              onPressed: () => _toggleFavorite(recipe),
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
      },
    );
  }

  Future<void> _rateRecipe(Recipe recipe, int rating) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentAppUser;
      if (currentUser == null) return;

      await context.read<AdminProvider>().recipes.rateRecipe(
        recipe.id,
        currentUser.uid,
        rating.toDouble(),
      );

      if (mounted) {
        // Refresh the recipe data to show updated ratings
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe rated $rating star${rating > 1 ? 's' : ''}!'),
            backgroundColor: NatureColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rate recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentAppUser;
      if (currentUser == null) return;

      await context.read<AdminProvider>().recipes.toggleFavorite(
        userId: currentUser.uid,
        recipeId: recipe.id,
      );

      if (mounted) {
        // Refresh the UI to show updated favorite status
        setState(() {});
        
        // Get current favorite status to show appropriate message
        final isCurrentlyFavorite = await context.read<AdminProvider>().recipes.watchIsFavorite(
          userId: currentUser.uid,
          recipeId: recipe.id,
        ).first;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFavorite 
              ? 'Recipe ${recipe.name} removed from favorites!' 
              : 'Recipe ${recipe.name} saved to favorites!'),
            backgroundColor: NatureColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBadge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildVisibilityChip(Recipe recipe) {
    final isPublic = recipe.visibility == RecipeVisibility.public;
    return _buildBadge(isPublic ? 'PUBLIC' : 'PRIVATE', isPublic ? Colors.green[800]! : Colors.grey[700]!, isPublic ? Colors.green[100]! : Colors.grey[200]!);
  }

  void _confirmDelete(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Delete "${recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AdminProvider>().deleteRecipe(recipe.id, reason: 'Admin delete');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
