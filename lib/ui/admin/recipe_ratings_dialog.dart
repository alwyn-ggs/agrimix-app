import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/admin_provider.dart';
import '../../theme/theme.dart';

class RecipeRatingsDialog extends StatefulWidget {
  final Recipe recipe;

  const RecipeRatingsDialog({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeRatingsDialog> createState() => _RecipeRatingsDialogState();
}

class _RecipeRatingsDialogState extends State<RecipeRatingsDialog> {
  List<Map<String, dynamic>> _ratings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      // Get ratings from the recipe's ratings subcollection
      final adminProvider = context.read<AdminProvider>();
      final ratingsSnapshot = await adminProvider.recipes.watchRecipeRatingsRaw(widget.recipe.id).first;

      setState(() {
        _ratings = ratingsSnapshot.map((data) {
          return {
            'id': data['userId'] ?? data['userUid'] ?? '',
            'userId': data['userId'] ?? data['userUid'] ?? '',
            'rating': data['rating'] ?? 0.0,
            'comment': data['comment'] ?? '',
            'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ratings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.rate_review, color: NatureColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ratings & Comments for "${widget.recipe.name}"',
                    style: const TextStyle(
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
            // Recipe Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NatureColors.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildInfoChip(Icons.star, '${widget.recipe.avgRating.toStringAsFixed(1)}/5.0'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.people, '${widget.recipe.totalRatings} ratings'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.favorite, '${widget.recipe.likes} likes'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Ratings List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _ratings.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review, size: 64, color: NatureColors.lightGray),
                              SizedBox(height: 16),
                              Text(
                                'No ratings yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: NatureColors.darkGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _ratings.length,
                          itemBuilder: (context, index) {
                            final rating = _ratings[index];
                            return _buildRatingCard(rating);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NatureColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NatureColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: NatureColors.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final ratingValue = (rating['rating'] as num).toDouble();
    final comment = rating['comment'] as String?;
    final createdAt = rating['createdAt'] as DateTime;
    final userId = rating['userId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Header
            Row(
              children: [
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < ratingValue ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  ratingValue.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // User ID (truncated)
                Text(
                  'User: ${userId.substring(0, 8)}...',
                  style: const TextStyle(
                    color: NatureColors.darkGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: NatureColors.darkGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                // Remove Button
                IconButton(
                  onPressed: () => _removeRating(rating),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  tooltip: 'Remove this rating',
                ),
              ],
            ),
            // Comment
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NatureColors.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  comment,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _removeRating(Map<String, dynamic> rating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Rating'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this rating? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmRemoveRating(rating);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveRating(Map<String, dynamic> rating) async {
    try {
      final userId = rating['userId'] as String;
      await context.read<AdminProvider>().removeRecipeRating(
        widget.recipe.id,
        userId,
        reason: 'Rating removed by admin',
      );

      // Reload ratings
      await _loadRatings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating removed successfully'),
            backgroundColor: NatureColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
