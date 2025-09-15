import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/recipe.dart';
import '../../theme/theme.dart';
import 'recipe_review_dialog.dart';
import 'recipe_ratings_dialog.dart';
import 'recipe_edit_dialog.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  RecipeMethod? _selectedMethod;
  bool _showStandardOnly = false;

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
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
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
                _buildReviewQueueTab(),
                _buildStandardRecipesTab(),
                _buildFlaggedRecipesTab(),
              ],
            ),
          ),
        ],
      ),
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
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Standard Only'),
                selected: _showStandardOnly,
                onSelected: (value) {
                  setState(() {
                    _showStandardOnly = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
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
          Tab(text: 'Review Queue'),
          Tab(text: 'Standard'),
          Tab(text: 'Flagged'),
        ],
      ),
    );
  }

  Widget _buildAllRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.allRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildReviewQueueTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.nonStandardRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildStandardRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.standardRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildFlaggedRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.flaggedRecipes;
        return _buildRecipesList(recipes);
      },
    );
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    if (recipes.isEmpty) {
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
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(recipe.name),
            subtitle: Text(recipe.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, recipe),
                ),
                IconButton(
                  icon: const Icon(Icons.rate_review),
                  onPressed: () => _showRatingsDialog(context, recipe),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeEditDialog(recipe: recipe),
    );
  }

  void _showRatingsDialog(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeRatingsDialog(recipe: recipe),
    );
  }
}