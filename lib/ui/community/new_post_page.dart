import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/theme.dart';
import '../../models/post.dart';
import '../../models/recipe.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  final List<File> _selectedImages = [];
  Recipe? _selectedRecipe;
  List<Recipe> _userRecipes = [];
  bool _isLoading = false;
  bool _isLoadingRecipes = false;
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserRecipes();
    // Move context-dependent operations to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForPreselectedRecipe();
  }

  void _checkForPreselectedRecipe() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final preselectedRecipe = args?['preselectedRecipe'] as Recipe?;
    
    if (preselectedRecipe != null) {
      setState(() {
        _selectedRecipe = preselectedRecipe;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      // Use a post-frame callback to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        final authProvider = context.read<AuthProvider>();
        
        if (authProvider.currentUser != null) {
          // Get recipes repository through the provider
          final recipeProvider = context.read<RecipeProvider>();
          final recipes = recipeProvider.items.where((recipe) => 
            recipe.ownerUid == authProvider.currentUser!.uid
          ).toList();
          
          if (mounted) {
            setState(() {
              _userRecipes = recipes;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What\'s this post about?',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Share your thoughts, experiences, or ask questions...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 16),
                    _buildRecipeSelectionSection(),
                    const SizedBox(height: 16),
                    _buildImagesSection(),
                    const SizedBox(height: 100), // Space for the floating button
                  ],
                ),
              ),
            ),
            _buildPostButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share Recipe (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: NatureColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingRecipes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_userRecipes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NatureColors.lightGray.withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NatureColors.lightGray.withAlpha((0.5 * 255).round())),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 32,
                    color: NatureColors.mediumGray,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No recipes found',
                    style: TextStyle(
                      fontSize: 14,
                      color: NatureColors.mediumGray,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a recipe first to share it',
                    style: TextStyle(
                      fontSize: 12,
                      color: NatureColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: NatureColors.lightGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_selectedRecipe != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: NatureColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRecipe!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: NatureColors.primaryGreen,
                                ),
                              ),
                              Text(
                                '${_selectedRecipe!.method.name} • ${_selectedRecipe!.cropTarget}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NatureColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedRecipe = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: _showRecipeSelectionDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: NatureColors.primaryGreen,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select a recipe to share',
                              style: TextStyle(
                                fontSize: 16,
                                color: NatureColors.darkGray,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: NatureColors.mediumGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _showRecipeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Recipe to Share'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _userRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _userRecipes[index];
              return ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(recipe.name),
                subtitle: Text('${recipe.method.name} • ${recipe.cropTarget}'),
                onTap: () {
                  setState(() {
                    _selectedRecipe = recipe;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }


  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images (${_selectedImages.length}/5)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: NatureColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NatureColors.primaryGreen,
                foregroundColor: NatureColors.pureWhite,
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedImages.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _clearImages,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: NatureColors.pureWhite,
                ),
              ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      
      if (images.isNotEmpty) {
        final newImages = images.map((image) => File(image.path)).toList();
        
        if (_selectedImages.length + newImages.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only select up to 5 images'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _selectedImages.addAll(newImages);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  Widget _buildPostButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NatureColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: NatureColors.primaryGreen,
              foregroundColor: NatureColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(NatureColors.pureWhite),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Post to Community',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final communityProvider = context.read<CommunityProvider>();
      
      // Show uploading images message
      if (_selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading images...'),
            backgroundColor: NatureColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await communityProvider.postsRepo.uploadPostImages(
          _selectedImages,
          currentUser.uid,
        );
      }

      // Show creating post message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating post...'),
          backgroundColor: NatureColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Create post
      final postData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'ownerUid': currentUser.uid,
        'ownerName': context.read<AuthProvider>().currentAppUser?.name,
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'images': imageUrls,
        'tags': [],
        'thumbsUp': 0,
        'thumbsDown': 0,
        'thumbsUpBy': [],
        'thumbsDownBy': [],
        'createdAt': DateTime.now(),
        'recipeId': _selectedRecipe?.id,
        'recipeName': _selectedRecipe?.name,
      };
      
      debugPrint('Creating post with data: $postData');
      
      final post = Post(
        id: postData['id'] as String,
        ownerUid: postData['ownerUid'] as String,
        ownerName: postData['ownerName'] as String?,
        title: postData['title'] as String,
        body: postData['body'] as String,
        images: _convertToStringList(postData['images']),
        tags: _convertToStringList(postData['tags']),
        likes: 0,
        likedBy: [],
        savedBy: [],
        createdAt: postData['createdAt'] as DateTime,
        recipeId: postData['recipeId'] as String?,
        recipeName: postData['recipeName'] as String?,
        thumbsUp: postData['thumbsUp'] as int,
        thumbsDown: postData['thumbsDown'] as int,
        thumbsUpBy: _convertToStringList(postData['thumbsUpBy']),
        thumbsDownBy: _convertToStringList(postData['thumbsDownBy']),
      );

      debugPrint('Post created successfully. Post toMap(): ${post.toMap()}');
      
      await communityProvider.postsRepo.createPost(post);
      
      // Refresh posts list
      await communityProvider.loadPosts(refresh: true);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<String> _convertToStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}