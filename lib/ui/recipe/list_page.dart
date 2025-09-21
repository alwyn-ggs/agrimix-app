import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../router.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/recipe.dart';
import '../../theme/theme.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      context.read<RecipeProvider>().loadFavorites(authProvider.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Recipes', style: TextStyle(color: Colors.white)),
        backgroundColor: NatureColors.primaryGreen,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list, color: Colors.white),
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilters(),
          const Divider(height: 1),
          Expanded(child: _buildRecipeList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search by crop, ingredient, or description...',
          hintStyle: const TextStyle(
            color: NatureColors.mediumGray,
            fontSize: 16,
          ),
          prefixIcon: const Icon(Icons.search, color: NatureColors.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: NatureColors.mediumGray),
                  onPressed: () {
                    _searchController.clear();
                    context.read<RecipeProvider>().setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NatureColors.mediumGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NatureColors.mediumGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NatureColors.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          context.read<RecipeProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: NatureColors.lightGray)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Consumer<RecipeProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<RecipeMethod?>(
                      value: provider.selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Method',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Methods')),
                        DropdownMenuItem(value: RecipeMethod.ffj, child: Text('FFJ')),
                        DropdownMenuItem(value: RecipeMethod.fpj, child: Text('FPJ')),
                      ],
                      onChanged: (value) => provider.setMethodFilter(value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<RecipeProvider>(
                  builder: (context, provider, child) {
                    return CheckboxListTile(
                      title: const Text('Standard Only'),
                      value: provider.standardOnly,
                      onChanged: (value) => provider.setStandardOnlyFilter(value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Consumer<RecipeProvider>(
                  builder: (context, provider, child) {
                    return CheckboxListTile(
                      title: const Text('Favorites Only'),
                      value: provider.showFavoritesOnly,
                      onChanged: (value) => provider.setFavoritesOnlyFilter(value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => context.read<RecipeProvider>().clearFilters(),
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Reload recipes by clearing and reapplying filters
                    provider.clearFilters();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final recipes = provider.filteredItems;

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 64, color: NatureColors.mediumGray),
                const SizedBox(height: 16),
                Text(
                  provider.searchQuery.isNotEmpty || provider.selectedMethod != null || provider.standardOnly || provider.showFavoritesOnly
                      ? 'No recipes match your filters'
                      : 'No recipes available',
                  style: const TextStyle(fontSize: 16, color: NatureColors.textDark),
                  textAlign: TextAlign.center,
                ),
                if (provider.searchQuery.isNotEmpty || provider.selectedMethod != null || provider.standardOnly || provider.showFavoritesOnly)
                  TextButton(
                    onPressed: () => provider.clearFilters(),
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return _buildRecipeCard(context, recipe);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(Routes.recipeDetail, arguments: {'id': recipe.id}),
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
                    width: 80,
                    height: 80,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NatureColors.textDark,
                          ),
                        ),
                        if (recipe.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            recipe.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: NatureColors.textDark,
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
                                color: recipe.method == RecipeMethod.ffj 
                                    ? NatureColors.lightGreen.withAlpha((0.2 * 255).round())
                                    : NatureColors.accentGreen.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                recipe.method.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: recipe.method == RecipeMethod.ffj 
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
                                  color: NatureColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  Consumer<RecipeProvider>(
                    builder: (context, provider, child) {
                      return IconButton(
                        onPressed: () {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.isLoggedIn) {
                            provider.toggleFavorite(authProvider.currentUser!.uid, recipe.id);
                          }
                        },
                        icon: Icon(
                          provider.isFavorite(recipe.id) ? Icons.favorite : Icons.favorite_border,
                          color: provider.isFavorite(recipe.id) ? Colors.red : NatureColors.mediumGray,
                        ),
                      );
                    },
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
                            color: NatureColors.textDark,
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
                  if (recipe.steps.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timeline,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.steps.length} steps',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (recipe.steps.isNotEmpty && recipe.isStandard) const SizedBox(width: 8),
                  if (recipe.isStandard)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: NatureColors.primaryGreen.withAlpha((0.5 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Standard',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NatureColors.primaryGreen,
                        ),
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
        borderRadius: BorderRadius.circular(8),
        color: NatureColors.lightGray,
      ),
      child: const Icon(
        Icons.restaurant_menu,
        color: NatureColors.mediumGray,
        size: 32,
      ),
    );
  }
}