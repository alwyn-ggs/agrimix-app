import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repositories/recipes_repo.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../router.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final recipeId = args?['id'] as String?;
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: recipeId == null
          ? const Center(child: Text('No recipe', style: TextStyle(color: Colors.black)))
          : _RecipeDetailBody(recipeId: recipeId),
    );
  }
}

class _RecipeDetailBody extends StatelessWidget {
  final String recipeId;
  const _RecipeDetailBody({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Recipe?>(
      future: context.read<RecipesRepo>().getRecipe(recipeId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Recipe not found', style: TextStyle(fontSize: 18, color: Colors.black)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        
        final recipe = snap.data!;
        final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
        
        return StreamBuilder<bool>(
          stream: context.read<RecipesRepo>().watchIsFavorite(userId: uid, recipeId: recipe.id),
          initialData: false,
          builder: (context, favSnap) {
            final isFav = favSnap.data ?? false;
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, recipe, isFav, uid),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRecipeInfo(recipe),
                        const SizedBox(height: 24),
                        _buildDescription(recipe),
                        const SizedBox(height: 24),
                        _buildIngredients(recipe),
                        const SizedBox(height: 24),
                        _buildSteps(recipe),
                        const SizedBox(height: 24),
                        _buildRatingSection(context, recipe),
                        const SizedBox(height: 24),
                        _buildCommentsSection(context, recipe),
                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Recipe recipe, bool isFav, String uid) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: NatureColors.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Recipe image
            if (recipe.imageUrls.isNotEmpty)
              Image.network(
                recipe.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              )
            else
              _buildImagePlaceholder(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha((0.7 * 255).round()),
                  ],
                ),
              ),
            ),
            // Recipe title and info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: recipe.method == RecipeMethod.FFJ 
                              ? NatureColors.lightGreen
                              : NatureColors.accentGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          recipe.method.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recipe.cropTarget,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
          onPressed: () => context.read<RecipesRepo>().toggleFavorite(userId: uid, recipeId: recipe.id),
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareRecipe(context, recipe),
        ),
        if (uid == recipe.ownerUid)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.of(context).pushNamed(Routes.recipeEdit, arguments: {'mode': 'edit', 'recipeId': recipe.id});
              } else if (value == 'delete') {
                _showDeleteDialog(context, recipe);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Recipe')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Recipe')),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: NatureColors.lightGray,
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 64,
          color: NatureColors.mediumGray,
        ),
      ),
    );
  }

  Widget _buildRecipeInfo(Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  recipe.avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${recipe.totalRatings} ratings)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: NatureColors.mediumGray,
                  ),
                ),
                const Spacer(),
                if (recipe.isStandard)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Standard Recipe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NatureColors.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${recipe.likes} likes',
                  style: const TextStyle(
                    fontSize: 16,
                    color: NatureColors.darkGray,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.visibility, color: NatureColors.mediumGray, size: 20),
                const SizedBox(width: 8),
                Text(
                  recipe.visibility == RecipeVisibility.public ? 'Public' : 'Private',
                  style: const TextStyle(
                    fontSize: 16,
                    color: NatureColors.mediumGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(Recipe recipe) {
    if (recipe.description.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.description,
              style: const TextStyle(
                fontSize: 16,
                color: NatureColors.darkGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredients(Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            if (recipe.ingredients.isEmpty)
              const Text(
                'No ingredients specified',
                style: TextStyle(
                  fontSize: 14,
                  color: NatureColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...recipe.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: NatureColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NatureColors.darkGray,
                        ),
                      ),
                    ),
                    Text(
                      '${ingredient.amount} ${ingredient.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NatureColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps(Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            if (recipe.steps.isEmpty)
              const Text(
                'No instructions provided',
                style: TextStyle(
                  fontSize: 14,
                  color: NatureColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...recipe.steps.map((step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: NatureColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${step.order}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        step.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NatureColors.darkGray,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Rate & Comment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openRateSheet(context, recipe.id),
                  icon: const Icon(Icons.star_rate),
                  label: const Text('Rate Recipe'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            _RecipeComments(recipeId: recipe.id),
          ],
        ),
      ),
    );
  }

  void _shareRecipe(BuildContext context, Recipe recipe) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: NatureColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NatureColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Share Recipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NatureColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.name,
              style: const TextStyle(
                fontSize: 16,
                color: NatureColors.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            
            // Share options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Share to Community
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: NatureColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Share to Community',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NatureColors.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Post this recipe in the community feed',
                      style: TextStyle(
                        color: NatureColors.mediumGray,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(
                        Routes.newPost,
                        arguments: {'preselectedRecipe': recipe},
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  // Share Externally
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NatureColors.accentGreen.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: NatureColors.accentGreen,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Share Externally',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NatureColors.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Share via email or other apps',
                      style: TextStyle(
                        color: NatureColors.mediumGray,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _shareRecipeExternally(context, recipe);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _shareRecipeExternally(BuildContext context, Recipe recipe) async {
    final url = 'https://agrimix.example/recipe/${recipe.id}';
    final text = 'Check out this recipe: ${recipe.name}\n$url';
    
    try {
      final uri = Uri.parse('mailto:?subject=${Uri.encodeComponent(recipe.name)}&body=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to copying to clipboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share link copied: $url'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard functionality would go here
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share link: $url')),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<RecipesRepo>().deleteRecipe(recipe.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recipe deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete recipe: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openRateSheet(BuildContext context, String recipeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RateCommentSheet(recipeId: recipeId),
    );
  }
}

class _RecipeComments extends StatelessWidget {
  final String recipeId;
  const _RecipeComments({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<RecipesRepo>().watchRecipeRatingsRaw(recipeId),
      builder: (context, snap) {
        final list = snap.data ?? const <Map<String, dynamic>>[];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No comments yet',
              style: TextStyle(
                color: NatureColors.mediumGray,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        
        final commentsWithRatings = list.where((r) => 
          (r['comment'] as String?)?.trim().isNotEmpty == true
        ).toList();
        
        if (commentsWithRatings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No comments yet',
              style: TextStyle(
                color: NatureColors.mediumGray,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        
        return Column(
          children: commentsWithRatings.map((comment) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: NatureColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: NatureColors.darkGreen,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (comment['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: NatureColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment['comment'] as String,
                    style: const TextStyle(
                      color: NatureColors.darkGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

class _RateCommentSheet extends StatefulWidget {
  final String recipeId;
  
  const _RateCommentSheet({required this.recipeId});

  @override
  State<_RateCommentSheet> createState() => _RateCommentSheetState();
}

class _RateCommentSheetState extends State<_RateCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 4.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NatureColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Rate & Comment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 20),
            
            // Star rating
            Row(
              children: [
                const Text(
                  'Rating:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NatureColors.darkGray,
                  ),
                ),
                const SizedBox(width: 16),
                ...List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = (index + 1).toDouble()),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Comment field
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your thoughts about this recipe...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: FilledButton.styleFrom(
                  backgroundColor: NatureColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      await context.read<RecipesRepo>().rateRecipe(
        widget.recipeId,
        uid,
        _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: NatureColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}