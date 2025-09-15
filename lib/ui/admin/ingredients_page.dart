import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/ingredient_seeder.dart';
import 'ingredient_management_screen.dart';

class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final items = provider.allIngredients;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions only
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IngredientManagementScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Ingredients',
                  value: items.length.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Categories',
                  value: items.map((i) => i.category).toSet().length.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Recommended Crops',
                  value: items.expand((i) => i.recommendedFor).toSet().length.toString(),
                  icon: Icons.eco,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showIngredientStats(context),
                icon: const Icon(Icons.analytics),
                label: const Text('View Stats'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ingredients list
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No ingredients in database',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Seed the database to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ingredient = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(ingredient.category).withOpacity(0.2),
                            child: Icon(
                              _getCategoryIcon(ingredient.category),
                              color: _getCategoryColor(ingredient.category),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (ingredient.recommendedFor.isNotEmpty)
                                Text(
                                  'Recommended for: ${ingredient.recommendedFor.take(2).join(', ')}${ingredient.recommendedFor.length > 2 ? '...' : ''}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const IngredientManagementScreen(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }


  void _showIngredientStats(BuildContext context) async {
    try {
      final stats = await IngredientSeeder.getIngredientStats();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ingredient Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Ingredients: ${stats['total'] ?? 0}'),
                Text('Categories: ${stats['categories'] ?? 0}'),
                Text('Recommended Crops: ${stats['crops'] ?? 0}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting stats: $e')),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Colors.orange;
      case 'flower':
        return Colors.pink;
      case 'plant':
        return Colors.green;
      case 'weed':
        return Colors.brown;
      case 'marine':
        return Colors.blue;
      case 'animal':
        return Colors.red;
      case 'fermentation aid':
        return Colors.purple;
      case 'root':
        return Colors.amber;
      default:
        return Colors.grey;
    }
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
