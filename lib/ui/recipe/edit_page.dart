import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/recipes_repo.dart';
import '../../models/recipe.dart';
import '../../theme/theme.dart';
import 'dart:io';

class RecipeEditPage extends StatelessWidget {
  const RecipeEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] as String?;
    final recipeId = args?['recipeId'] as String?;
    final forceStandard = (args?['forceStandard'] as bool?) ?? false;
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: Text(
          mode == 'create' ? 'Create Recipe' : 'Edit Recipe',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: NatureColors.primaryGreen,
      ),
      body: _RecipeForm(mode: mode, recipeId: recipeId, forceStandard: forceStandard),
    );
  }
}

class _RecipeForm extends StatefulWidget {
  final String? mode;
  final String? recipeId;
  final bool forceStandard;
  const _RecipeForm({this.mode, this.recipeId, this.forceStandard = false});

  @override
  State<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<_RecipeForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _crop = TextEditingController();
  RecipeMethod _method = RecipeMethod.ffj;
  RecipeVisibility _visibility = RecipeVisibility.private;
  final List<File> _images = [];
  List<String> _imageUrls = [];
  List<RecipeIngredient> _ingredients = [];
  List<RecipeStep> _steps = [];
  bool _saving = false;
  bool _isLoading = false;
  Recipe? _existingRecipe;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'edit' && widget.recipeId != null) {
      _loadExistingRecipe();
    }
    // If admin invoked Standard creation, default fields accordingly
    if (widget.mode == 'create' && widget.forceStandard) {
      _visibility = RecipeVisibility.public;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _crop.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRecipe() async {
    setState(() => _isLoading = true);
    try {
      final recipe = await context.read<RecipesRepo>().getRecipe(widget.recipeId!);
      if (recipe != null && mounted) {
        setState(() {
          _existingRecipe = recipe;
          _name.text = recipe.name;
          _description.text = recipe.description;
          _crop.text = recipe.cropTarget;
          _method = recipe.method;
          _visibility = recipe.visibility;
          _imageUrls = List.from(recipe.imageUrls);
          _ingredients = List.from(recipe.ingredients);
          _steps = List.from(recipe.steps);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildImagesSection(),
            const SizedBox(height: 24),
            _buildIngredientsSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
            const SizedBox(height: 24),
            _buildVisibilitySection(),
            const SizedBox(height: 16),
            if (widget.forceStandard)
              const Text(
                'This will be saved as a Standard recipe and visible to all users.',
                style: TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Recipe Name *',
                hintText: 'Enter recipe name',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Recipe name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your recipe...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _crop,
              decoration: const InputDecoration(
                labelText: 'Crop Target',
                hintText: 'e.g., Tomatoes, Lettuce, etc.',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RecipeMethod>(
                    value: _method,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: RecipeMethod.ffj, child: Text('FFJ')),
                      DropdownMenuItem(value: RecipeMethod.fpj, child: Text('FPJ')),
                    ],
                    onChanged: (v) => setState(() => _method = v ?? RecipeMethod.ffj),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty || _imageUrls.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + _imageUrls.length,
                  itemBuilder: (context, index) {
                    if (index < _images.length) {
                      return _buildImagePreview(_images[index], isLocal: true, index: index);
                    } else {
                      final urlIndex = index - _images.length;
                      return _buildImagePreview(File(''), isLocal: false, url: _imageUrls[urlIndex], index: index);
                    }
                  },
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NatureColors.primaryGreen,
                side: const BorderSide(color: NatureColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image, {required bool isLocal, String? url, required int index}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NatureColors.mediumGray),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocal
                ? Image.file(image, fit: BoxFit.cover, width: 120, height: 120)
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ingredients.isEmpty)
              const Text(
                'No ingredients added yet',
                style: TextStyle(
                  color: NatureColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return _buildIngredientItem(ingredient, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(RecipeIngredient ingredient, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: NatureColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(ingredient.name),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${ingredient.amount} ${ingredient.unit}'),
          ),
          IconButton(
            onPressed: () => _removeIngredient(index),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_steps.isEmpty)
              const Text(
                'No instructions added yet',
                style: TextStyle(
                  color: NatureColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return _buildStepItem(step, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(RecipeStep step, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: NatureColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(step.text)),
          IconButton(
            onPressed: () => _removeStep(index),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visibility',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecipeVisibility>(
              value: _visibility,
              decoration: const InputDecoration(
                labelText: 'Recipe Visibility',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen, width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: RecipeVisibility.public,
                  child: Text('Public - Visible to all users'),
                ),
                DropdownMenuItem(
                  value: RecipeVisibility.private,
                  child: Text('Private - Only visible to you'),
                ),
              ],
              onChanged: (v) => setState(() => _visibility = v ?? RecipeVisibility.private),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: NatureColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.mode == 'create' ? 'Create Recipe' : 'Update Recipe',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _images.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _images.length) {
        _images.removeAt(index);
      } else {
        final urlIndex = index - _images.length;
        _imageUrls.removeAt(urlIndex);
      }
    });
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        onSave: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _StepDialog(
        stepNumber: _steps.length + 1,
        onSave: (step) {
          setState(() {
            _steps.add(step);
          });
        },
      ),
    );
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Reorder remaining steps
      for (int i = index; i < _steps.length; i++) {
        _steps[i] = RecipeStep(order: i + 1, text: _steps[i].text);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    try {
      final recipes = context.read<RecipesRepo>();
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      
      // Upload images if any
      List<String> uploadedImageUrls = List.from(_imageUrls);
      for (final image in _images) {
        try {
          final url = await recipes.uploadRecipeImage(
            _existingRecipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            uid,
            image,
          );
          uploadedImageUrls.add(url);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
        }
      }
      
      final now = DateTime.now();
      final recipe = Recipe(
        id: _existingRecipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerUid: uid,
        name: _name.text.trim(),
        description: _description.text.trim(),
        method: _method,
        cropTarget: _crop.text.trim(),
        ingredients: _ingredients,
        steps: _steps,
        visibility: _visibility,
        isStandard: widget.forceStandard ? true : (_existingRecipe?.isStandard ?? false),
        likes: _existingRecipe?.likes ?? 0,
        avgRating: _existingRecipe?.avgRating ?? 0.0,
        totalRatings: _existingRecipe?.totalRatings ?? 0,
        imageUrls: uploadedImageUrls,
        createdAt: _existingRecipe?.createdAt ?? now,
        updatedAt: now,
      );
      
      if (widget.mode == 'create') {
        await recipes.createRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe created successfully!'),
              backgroundColor: NatureColors.primaryGreen,
            ),
          );
        }
      } else {
        await recipes.updateRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe updated successfully!'),
              backgroundColor: NatureColors.primaryGreen,
            ),
          );
        }
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _IngredientDialog extends StatefulWidget {
  final Function(RecipeIngredient) onSave;
  
  const _IngredientDialog({required this.onSave});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ingredient Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    hintText: 'kg, g, ml, etc.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && 
                _amountController.text.isNotEmpty && 
                _unitController.text.isNotEmpty) {
              final ingredient = RecipeIngredient(
                ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                amount: double.tryParse(_amountController.text) ?? 0.0,
                unit: _unitController.text.trim(),
              );
              widget.onSave(ingredient);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _StepDialog extends StatefulWidget {
  final int stepNumber;
  final Function(RecipeStep) onSave;
  
  const _StepDialog({required this.stepNumber, required this.onSave});

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Step ${widget.stepNumber}'),
      content: TextField(
        controller: _textController,
        decoration: const InputDecoration(
          labelText: 'Step Description',
          border: OutlineInputBorder(),
          hintText: 'Describe this step...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_textController.text.isNotEmpty) {
              final step = RecipeStep(
                order: widget.stepNumber,
                text: _textController.text.trim(),
              );
              widget.onSave(step);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}