import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/admin_provider.dart';
import '../../theme/theme.dart';

class RecipeEditDialog extends StatefulWidget {
  final Recipe recipe;

  const RecipeEditDialog({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeEditDialog> createState() => _RecipeEditDialogState();
}

class _RecipeEditDialogState extends State<RecipeEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _cropTargetController;
  late RecipeMethod _selectedMethod;
  late RecipeVisibility _selectedVisibility;
  bool _isStandard = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _cropTargetController = TextEditingController(text: widget.recipe.cropTarget);
    _selectedMethod = widget.recipe.method;
    _selectedVisibility = widget.recipe.visibility;
    _isStandard = widget.recipe.isStandard;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cropTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: NatureColors.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Edit Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipe Name *',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: NatureColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: NatureColors.primaryGreen),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cropTargetController,
                      decoration: const InputDecoration(
                        labelText: 'Crop Target *',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: NatureColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Method and Visibility
                    const Text(
                      'Recipe Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RecipeMethod>(
                            value: _selectedMethod,
                            decoration: const InputDecoration(
                              labelText: 'Method',
                              border: OutlineInputBorder(),
                            ),
                            items: RecipeMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<RecipeVisibility>(
                            value: _selectedVisibility,
                            decoration: const InputDecoration(
                              labelText: 'Visibility',
                              border: OutlineInputBorder(),
                            ),
                            items: RecipeVisibility.values.map((visibility) {
                              return DropdownMenuItem(
                                value: visibility,
                                child: Text(visibility.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVisibility = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Admin Settings
                    const Text(
                      'Admin Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: NatureColors.warning.withAlpha((0.3 * 255).round()),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: NatureColors.warning),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Mark as Standard Recipe',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Switch(
                              value: _isStandard,
                              onChanged: (value) {
                                setState(() {
                                  _isStandard = value;
                                });
                              },
                              activeColor: NatureColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Ingredients and Steps (Read-only for now)
                    const Text(
                      'Recipe Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NatureColors.lightGray.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NatureColors.lightGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingredients (${widget.recipe.ingredients.length})',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ...widget.recipe.ingredients.take(3).map((ingredient) => 
                            Text('• ${ingredient.name} - ${ingredient.amount} ${ingredient.unit}')
                          ),
                          if (widget.recipe.ingredients.length > 3)
                            Text('... and ${widget.recipe.ingredients.length - 3} more'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NatureColors.lightGray.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NatureColors.lightGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Steps (${widget.recipe.steps.length})',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ...widget.recipe.steps.take(2).map((step) => 
                            Text('${step.order}. ${step.text}')
                          ),
                          if (widget.recipe.steps.length > 2)
                            Text('... and ${widget.recipe.steps.length - 2} more steps'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _cropTargetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedRecipe = widget.recipe.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        cropTarget: _cropTargetController.text.trim(),
        method: _selectedMethod,
        visibility: _selectedVisibility,
        isStandard: _isStandard,
        updatedAt: DateTime.now(),
      );

      await context.read<AdminProvider>().recipes.updateRecipe(updatedRecipe);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe updated successfully'),
            backgroundColor: NatureColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
