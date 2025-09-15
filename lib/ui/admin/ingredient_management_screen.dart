import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/ingredients_repo.dart';
import '../../models/ingredient.dart';
import '../../utils/ingredient_seeder.dart';
import '../../theme/theme.dart';

class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  State<IngredientManagementScreen> createState() => _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  void _updateCategories() {
    final recipeProvider = context.read<RecipeProvider>();
    final categories = recipeProvider.allIngredients
        .map((ing) => ing.category)
        .toSet()
        .toList();
    categories.sort();
    setState(() {
      _categories = ['All', ...categories];
    });
  }

  List<Ingredient> get _filteredIngredients {
    final recipeProvider = context.read<RecipeProvider>();
    List<Ingredient> list = recipeProvider.allIngredients;

    // Filter by category
    if (_selectedCategory != 'All') {
      list = list.where((ing) => ing.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((ing) => 
        ing.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        ing.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
      ).toList();
    }

    return list;
  }



  Future<void> _deleteIngredient(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete "${ingredient.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final ingredientsRepo = context.read<IngredientsRepo>();
        final authProvider = context.read<AuthProvider>();
        
        await ingredientsRepo.deleteIngredient(ingredient.id);
        
        // Admin action completed
        
        _updateCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ingredient.name} deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting ingredient: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final filteredIngredients = _filteredIngredients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Management', style: TextStyle(color: Colors.white)),
        backgroundColor: NatureColors.lightGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddIngredientDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with stats and actions
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Ingredients: ${recipeProvider.allIngredients.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search and filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          labelText: 'Search ingredients...',
                          labelStyle: const TextStyle(color: Colors.black),
                          floatingLabelStyle: const TextStyle(color: Colors.black),
                          hintText: 'e.g., banana, moringa, leaves',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(Icons.search, color: NatureColors.lightGreen),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: NatureColors.lightGreen, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: NatureColors.lightGreen.withOpacity(0.5), width: 1),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: NatureColors.lightGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category in _categories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() => _selectedCategory = selected ? category : 'All');
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ingredients list
                Expanded(
                  child: filteredIngredients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ingredients found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or add some ingredients',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = filteredIngredients[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white,
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: NatureColors.lightGreen.withOpacity(0.2),
                                  child: Icon(
                                    _getCategoryIcon(ingredient.category),
                                    color: NatureColors.lightGreen,
                                  ),
                                ),
                                title: Text(
                                  ingredient.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Category: ${ingredient.category}',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                    if (ingredient.description != null && ingredient.description!.isNotEmpty)
                                      Text(
                                        ingredient.description!,
                                        style: const TextStyle(color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (ingredient.recommendedFor.isNotEmpty)
                                      Wrap(
                                        children: [
                                          const Text(
                                            'Recommended for: ', 
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          ...ingredient.recommendedFor.take(3).map((crop) => 
                                            Text(
                                              '$crop, ',
                                              style: const TextStyle(color: Colors.black87),
                                            )
                                          ),
                                          if (ingredient.recommendedFor.length > 3)
                                            Text(
                                              'and ${ingredient.recommendedFor.length - 3} more...',
                                              style: const TextStyle(color: Colors.black54),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.black87),
                                          SizedBox(width: 8),
                                          Text('Edit', style: TextStyle(color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditIngredientDialog(ingredient);
                                    } else if (value == 'delete') {
                                      _deleteIngredient(ingredient);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredientDialog,
        backgroundColor: NatureColors.lightGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Icons.local_fire_department;
      case 'flower':
        return Icons.local_florist;
      case 'plant':
        return Icons.eco;
      case 'weed':
        return Icons.grass;
      case 'marine':
        return Icons.waves;
      case 'animal':
        return Icons.pets;
      case 'fermentation aid':
        return Icons.science;
      case 'root':
        return Icons.park;
      default:
        return Icons.eco;
    }
  }

  void _showAddIngredientDialog() {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        onSave: (ingredient) async {
          try {
            final ingredientsRepo = context.read<IngredientsRepo>();
            final authProvider = context.read<AuthProvider>();
            
            await ingredientsRepo.createIngredient(ingredient);
            
            // Admin action completed
            
            _updateCategories();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${ingredient.name} added successfully!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding ingredient: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditIngredientDialog(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        ingredient: ingredient,
        onSave: (updatedIngredient) async {
          try {
            final ingredientsRepo = context.read<IngredientsRepo>();
            final authProvider = context.read<AuthProvider>();
            
            await ingredientsRepo.updateIngredient(updatedIngredient);
            
            // Admin action completed
            
            _updateCategories();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${updatedIngredient.name} updated successfully!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating ingredient: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  final Ingredient? ingredient;
  final Function(Ingredient) onSave;

  const _IngredientDialog({
    this.ingredient,
    required this.onSave,
  });

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _recommendedController;
  late TextEditingController _precautionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    _categoryController = TextEditingController(text: widget.ingredient?.category ?? '');
    _descriptionController = TextEditingController(text: widget.ingredient?.description ?? '');
    _recommendedController = TextEditingController(
      text: widget.ingredient?.recommendedFor.join(', ') ?? '',
    );
    _precautionsController = TextEditingController(
      text: widget.ingredient?.precautions.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _recommendedController.dispose();
    _precautionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Fruit, Plant, Weed',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recommendedController,
              decoration: const InputDecoration(
                labelText: 'Recommended For',
                border: OutlineInputBorder(),
                hintText: 'e.g., tomato, pepper, rice (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precautionsController,
              decoration: const InputDecoration(
                labelText: 'Precautions',
                border: OutlineInputBorder(),
                hintText: 'e.g., Use fresh, Avoid mold (comma separated)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveIngredient,
          child: Text(widget.ingredient == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveIngredient() {
    if (_nameController.text.trim().isEmpty || _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and category are required')),
      );
      return;
    }

    final recommendedFor = _recommendedController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    final precautions = _precautionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final ingredient = Ingredient(
      id: widget.ingredient?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      recommendedFor: recommendedFor,
      precautions: precautions,
      createdAt: widget.ingredient?.createdAt ?? DateTime.now(),
    );

    widget.onSave(ingredient);
    Navigator.of(context).pop();
  }
}
