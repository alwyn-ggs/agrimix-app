import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/recipe.dart';
import '../../theme/theme.dart';
import 'recipe_review_dialog.dart';
import 'recipe_ratings_dialog.dart';
import 'recipe_edit_dialog.dart';

class RecipesPageComplete extends StatefulWidget {
  const RecipesPageComplete({super.key});

  @override
  State<RecipesPageComplete> createState() => _RecipesPageCompleteState();
}

class _RecipesPageCompleteState extends State<RecipesPageComplete> with TickerProviderStateMixin {
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
      decoration: BoxDecoration(
        color: NatureColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: NatureColors.darkGray.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          prefixIcon: const Icon(Icons.search, color: NatureColors.darkGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NatureColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NatureColors.primaryGreen),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: NatureColors.pureWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: NatureColors.primaryGreen,
        unselectedLabelColor: NatureColors.darkGray,
        indicatorColor: NatureColors.primaryGreen,
        tabs: const [
          Tab(text: 'All Recipes', icon: Icon(Icons.restaurant_menu)),
          Tab(text: 'Review Queue', icon: Icon(Icons.queue)),
          Tab(text: 'Standard', icon: Icon(Icons.star)),
          Tab(text: 'Flagged', icon: Icon(Icons.flag)),
        ],
      ),
    );
  }

  Widget _buildAllRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.allRecipes;
        
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: NatureColors.lightGray),
                SizedBox(height: 16),
                Text(
                  'No recipes found',
                  style: TextStyle(fontSize: 18, color: NatureColors.darkGray),
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
            return _buildRecipeCard(recipe);
          },
        );
      },
    );
  }

  Widget _buildReviewQueueTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final pendingRecipes = adminProvider.nonStandardRecipes;
        
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pendingRecipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.queue, size: 64, color: NatureColors.lightGray),
                SizedBox(height: 16),
                Text(
                  'No recipes pending review',
                  style: TextStyle(fontSize: 18, color: NatureColors.darkGray),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRecipes.length,
          itemBuilder: (context, index) {
            final recipe = pendingRecipes[index];
            return _buildReviewRecipeCard(recipe);
          },
        );
      },
    );
  }

  Widget _buildStandardRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.standardRecipes;
        
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 64, color: NatureColors.lightGray),
                SizedBox(height: 16),
                Text(
                  'No standard recipes',
                  style: TextStyle(fontSize: 18, color: NatureColors.darkGray),
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
            return _buildRecipeCard(recipe);
          },
        );
      },
    );
  }

  Widget _buildFlaggedRecipesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final recipes = adminProvider.flaggedRecipes;
        
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, size: 64, color: NatureColors.lightGray),
                SizedBox(height: 16),
                Text(
                  'No flagged recipes',
                  style: TextStyle(fontSize: 18, color: NatureColors.darkGray),
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
            return _buildFlaggedRecipeCard(recipe);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NatureColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          color: NatureColors.darkGray,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (recipe.isStandard)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NatureColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'STANDARD',
                      style: TextStyle(
                        color: NatureColors.pureWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.local_dining, recipe.method.name),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.eco, recipe.cropTarget),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.star, '${recipe.avgRating.toStringAsFixed(1)} (${recipe.totalRatings})'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.favorite, '${recipe.likes}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRecipeRatings(recipe),
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Ratings'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editRecipe(recipe),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                if (!recipe.isStandard)
                  TextButton.icon(
                    onPressed: () => _markAsStandard(recipe),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Mark Standard'),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteRecipe(recipe),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NatureColors.warning, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.queue, color: NatureColors.warning, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'PENDING REVIEW',
                    style: TextStyle(
                      color: NatureColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Created: ${_formatDate(recipe.createdAt)}',
                    style: const TextStyle(
                      color: NatureColors.darkGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NatureColors.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recipe.description,
                style: const TextStyle(
                  color: NatureColors.darkGray,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.local_dining, recipe.method.name),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.eco, recipe.cropTarget),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.star, '${recipe.avgRating.toStringAsFixed(1)} (${recipe.totalRatings})'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRecipeRatings(recipe),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _rejectRecipe(recipe),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRecipe(recipe),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NatureColors.primaryGreen,
                      foregroundColor: Colors.white,
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

  Widget _buildFlaggedRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'FLAGGED - LOW RATING',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rating: ${recipe.avgRating.toStringAsFixed(1)}/5.0',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NatureColors.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recipe.description,
                style: const TextStyle(
                  color: NatureColors.darkGray,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.local_dining, recipe.method.name),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.eco, recipe.cropTarget),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.star, '${recipe.avgRating.toStringAsFixed(1)} (${recipe.totalRatings})'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRecipeRatings(recipe),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('View Ratings'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _editRecipe(recipe),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteRecipe(recipe),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NatureColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NatureColors.darkGray),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: NatureColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRecipeRatings(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeRatingsDialog(recipe: recipe),
    );
  }

  void _editRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeEditDialog(recipe: recipe),
    );
  }

  void _approveRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeReviewDialog(
        recipe: recipe,
        action: 'approve',
        onConfirm: (reason) async {
          try {
            await context.read<AdminProvider>().approveRecipe(recipe.id, reason: reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recipe approved successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error approving recipe: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _rejectRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeReviewDialog(
        recipe: recipe,
        action: 'reject',
        onConfirm: (reason) async {
          try {
            await context.read<AdminProvider>().rejectRecipe(recipe.id, reason: reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recipe rejected and deleted')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error rejecting recipe: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _markAsStandard(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeReviewDialog(
        recipe: recipe,
        action: 'mark_standard',
        onConfirm: (reason) async {
          try {
            await context.read<AdminProvider>().markAsStandard(recipe.id, reason: reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recipe marked as standard')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error marking recipe as standard: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => RecipeReviewDialog(
        recipe: recipe,
        action: 'delete',
        onConfirm: (reason) async {
          try {
            await context.read<AdminProvider>().deleteRecipe(recipe.id, reason: reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recipe deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting recipe: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
