  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
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

  class _RecipeDetailBody extends StatefulWidget {
    final String recipeId;
    const _RecipeDetailBody({required this.recipeId});

    @override
    State<_RecipeDetailBody> createState() => _RecipeDetailBodyState();
  }

  class _RecipeDetailBodyState extends State<_RecipeDetailBody> {
    late Future<Recipe?> _recipeFuture;

    @override
    void initState() {
      super.initState();
      _recipeFuture = context.read<RecipesRepo>().getRecipe(widget.recipeId);
    }

    @override
    Widget build(BuildContext context) {
      return FutureBuilder<Recipe?>(
        future: _recipeFuture,
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
          final auth = context.read<AuthProvider>();
          final uid = auth.currentUser?.uid ?? '';
          final isAdmin = (auth.currentAppUser?.role.toLowerCase() == 'admin');
          
          return StreamBuilder<bool>(
            stream: context.read<RecipesRepo>().watchIsFavorite(userId: uid, recipeId: recipe.id),
            initialData: false,
            builder: (context, favSnap) {
              final isFav = favSnap.data ?? false;
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, recipe, isFav, uid, isAdmin),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecipeInfo(context, recipe),
                          const SizedBox(height: 24),
                          _buildDescription(recipe),
                          const SizedBox(height: 24),
                          _buildIngredients(recipe),
                          const SizedBox(height: 24),
                          _buildSteps(recipe),
                          const SizedBox(height: 24),
                          // Start fermenting for drafts (private) owned by user
                          if (recipe.visibility == RecipeVisibility.private && uid == recipe.ownerUid)
                            SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    Routes.newLog,
                                    arguments: {'recipe': recipe},
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.play_circle_fill, size: 18),
                                  label: const Text('Start Fermenting'),
                                ),
                              ),
                            ),
                          if (recipe.visibility == RecipeVisibility.private && uid == recipe.ownerUid)
                            const SizedBox(height: 24),
                          if (_shouldShowUseButton(uid, recipe))
                            SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _useThisRecipe(context, recipe, uid),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: NatureColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.playlist_add, size: 18),
                                  label: const Text('Use this recipe'),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
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

    Widget _buildAppBar(BuildContext context, Recipe recipe, bool isFav, String uid, bool isAdmin) {
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
                            color: recipe.method == RecipeMethod.ffj 
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
          if (!recipe.isStandard && recipe.visibility == RecipeVisibility.public && uid != recipe.ownerUid)
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
              onPressed: () => context.read<RecipesRepo>().toggleFavorite(userId: uid, recipeId: recipe.id),
            ),
          if (uid == recipe.ownerUid)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareRecipe(context, recipe),
            ),
          if (uid == recipe.ownerUid)
            Builder(
              builder: (menuContext) {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () async {
                    final button = menuContext.findRenderObject() as RenderBox?;
                    final overlayBox = Navigator.of(menuContext).overlay?.context.findRenderObject() as RenderBox?;
                    if (button == null || overlayBox == null) return;
                    final position = RelativeRect.fromRect(
                      button.localToGlobal(Offset.zero, ancestor: overlayBox) & button.size,
                      Offset.zero & overlayBox.size,
                    );

                    final selected = await showMenu<String>(
                      context: Navigator.of(menuContext).overlay!.context,
                      position: position,
                      items: const [
                        PopupMenuItem(value: 'edit', child: Text('Edit Recipe')),
                        PopupMenuItem(value: 'delete', child: Text('Delete Recipe')),
                      ],
                    );

                    if (selected == 'edit') {
                      if (menuContext.mounted) {
                        Navigator.of(menuContext).pushNamed(
                          Routes.recipeEdit,
                          arguments: {
                            'mode': 'edit',
                            'recipeId': recipe.id,
                            'forceStandard': recipe.isStandard,
                          },
                        );
                      }
                    } else if (selected == 'delete') {
                      if (menuContext.mounted) {
                        _showDeleteDialog(menuContext, recipe);
                      }
                    }
                  },
                );
              },
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

    bool _shouldShowUseButton(String uid, Recipe recipe) {
      if (uid.isEmpty) return false;
      if (uid == recipe.ownerUid) return false;
      if (recipe.isStandard) return true;
      return recipe.visibility == RecipeVisibility.public;
    }

    Future<void> _useThisRecipe(BuildContext context, Recipe source, String uid) async {
      try {
        final repo = context.read<RecipesRepo>();
        final newId = FirebaseFirestore.instance.collection(Recipe.collectionPath).doc().id;
        final copy = Recipe(
          id: newId,
          ownerUid: uid,
          name: source.name,
          description: source.description,
          method: source.method,
          cropTarget: source.cropTarget,
          ingredients: source.ingredients,
          steps: source.steps,
          visibility: RecipeVisibility.private,
          isStandard: false,
          likes: 0,
          avgRating: 0.0,
          totalRatings: 0,
          imageUrls: source.imageUrls,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createRecipe(copy);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to your Drafts. Edit and share when ready.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to use recipe: $e')),
          );
        }
      }
    }

    Widget _buildRecipeInfo(BuildContext context, Recipe recipe) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              recipe.isStandard
                  ? Row(
                      children: [
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: NatureColors.lightGray.withAlpha((0.3 * 255).round()),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            recipe.visibility == RecipeVisibility.public ? 'Public' : 'Private',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NatureColors.darkGray,
                            ),
                          ),
                        ),
                      ],
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: context.read<RecipesRepo>().watchRecipeRatingsRaw(recipe.id),
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
                        return Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: NatureColors.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($count ratings)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.mediumGray,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!recipe.isStandard) ...[
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
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
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
                      onTap: () async {
                        Navigator.pop(context);
                        Recipe recipeToShare = recipe;
                        try {
                          // If it's a draft (private), create a public copy instead of converting the draft
                          if (recipe.visibility == RecipeVisibility.private) {
                            final newId = FirebaseFirestore.instance.collection(Recipe.collectionPath).doc().id;
                            final publicCopy = Recipe(
                              id: newId,
                              ownerUid: recipe.ownerUid,
                              name: recipe.name,
                              description: recipe.description,
                              method: recipe.method,
                              cropTarget: recipe.cropTarget,
                              ingredients: recipe.ingredients,
                              steps: recipe.steps,
                              visibility: RecipeVisibility.public,
                              isStandard: false,
                              likes: 0,
                              avgRating: 0.0,
                              totalRatings: 0,
                              imageUrls: recipe.imageUrls,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await context.read<RecipesRepo>().createRecipe(publicCopy);
                            recipeToShare = publicCopy;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recipe shared publicly and kept in Drafts.')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recipe is public and visible in Recipes tab.')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to share recipe: $e')),
                            );
                          }
                        }

                        if (context.mounted) {
                          Navigator.of(context).pushNamed(
                            Routes.newPost,
                            arguments: {'preselectedRecipe': recipeToShare},
                          );
                        }
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

  }

  

  