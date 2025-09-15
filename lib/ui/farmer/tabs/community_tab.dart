import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../community/post_list_page.dart';
import '../../community/saved_posts_page.dart';
import '../../../providers/moderation_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/theme.dart';
import '../../../models/violation.dart';
import '../farmer_community_moderation_page.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final moderationProvider = context.read<ModerationProvider>();
    final communityProvider = context.read<CommunityProvider>();
    
    // Load violations for moderation
    moderationProvider.refreshViolations();
    // Load posts for community feed
    communityProvider.loadPosts(refresh: true);
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
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              // Navigate to saved posts page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPostsPage(),
                ),
              );
            },
            tooltip: 'Saved Posts',
          ),
          Consumer<ModerationProvider>(
            builder: (context, moderationProvider, child) {
              final openViolationsCount = moderationProvider.openViolationsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FarmerCommunityModerationPage(),
                      ),
                    ),
                    tooltip: 'Moderation Panel',
                  ),
                  if (openViolationsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$openViolationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: NatureColors.pureWhite,
          unselectedLabelColor: NatureColors.lightGray,
          indicatorColor: NatureColors.pureWhite,
          tabs: const [
            Tab(
              child: Icon(Icons.article_outlined, size: 20),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Moderation'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const PostListPage(),
          _buildModerationTab(),
        ],
      ),
    );
  }

  Widget _buildModerationTab() {
    return Consumer<ModerationProvider>(
      builder: (context, moderationProvider, child) {
        if (moderationProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (moderationProvider.openViolations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: NatureColors.lightGray,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No pending reports',
                  style: TextStyle(
                    fontSize: 18,
                    color: NatureColors.lightGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All community content is clean!',
                  style: TextStyle(
                    color: NatureColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: NatureColors.pureWhite,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: moderationProvider.openViolations.length,
          itemBuilder: (context, index) {
            final violation = moderationProvider.openViolations[index];
            return _buildViolationCard(violation);
          },
        );
      },
    );
  }

  Widget _buildViolationCard(Violation violation) {
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
                Icon(
                  _getViolationIcon(violation.targetType),
                  color: _getViolationColor(violation.targetType),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reported ${violation.targetType.name.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${violation.reason}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported by: ${violation.reporterUid?.substring(0, 8) ?? 'Unknown'}...',
              style: const TextStyle(
                color: NatureColors.mediumGray,
                fontSize: 12,
              ),
            ),
            Text(
              'Reported: ${_formatDate(violation.createdAt)}',
              style: const TextStyle(
                color: NatureColors.mediumGray,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleViolationAction('dismiss', violation),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Dismiss'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleViolationAction('warn', violation),
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Warn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleViolationAction('delete', violation),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getViolationIcon(ViolationTargetType targetType) {
    switch (targetType) {
      case ViolationTargetType.post:
        return Icons.article_outlined;
      case ViolationTargetType.comment:
        return Icons.comment_outlined;
      case ViolationTargetType.recipe:
        return Icons.restaurant_menu_outlined;
      case ViolationTargetType.user:
        return Icons.person_outlined;
    }
  }

  Color _getViolationColor(ViolationTargetType targetType) {
    switch (targetType) {
      case ViolationTargetType.post:
        return Colors.blue;
      case ViolationTargetType.comment:
        return Colors.green;
      case ViolationTargetType.recipe:
        return Colors.orange;
      case ViolationTargetType.user:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleViolationAction(String action, Violation violation) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    switch (action) {
      case 'dismiss':
        _showDismissDialog(violation);
        break;
      case 'warn':
        _showWarnDialog(violation);
        break;
      case 'delete':
        _showDeleteDialog(violation);
        break;
    }
  }

  void _showDismissDialog(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: const Text('Are you sure you want to dismiss this report? This will mark it as resolved without taking any action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final moderationProvider = context.read<ModerationProvider>();
              final currentUser = context.read<AuthProvider>().currentUser;
              if (currentUser != null) {
                moderationProvider.dismissViolation(
                  violation.id,
                  currentUser.uid,
                  reason: 'Dismissed by farmer moderator',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report dismissed successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _showWarnDialog(Violation violation) {
    final TextEditingController warningController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a warning message for the user:'),
            const SizedBox(height: 16),
            TextField(
              controller: warningController,
              decoration: const InputDecoration(
                hintText: 'Enter warning message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (warningController.text.trim().isNotEmpty) {
                final moderationProvider = context.read<ModerationProvider>();
                final currentUser = context.read<AuthProvider>().currentUser;
                if (currentUser != null) {
                  moderationProvider.warnUser(
                    violation.id,
                    currentUser.uid,
                    warningMessage: warningController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User warned successfully')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Warn User'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete this ${violation.targetType.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final moderationProvider = context.read<ModerationProvider>();
              final currentUser = context.read<AuthProvider>().currentUser;
              if (currentUser != null) {
                moderationProvider.deleteContent(
                  violation.id,
                  currentUser.uid,
                  reason: 'Deleted by farmer moderator',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${violation.targetType.name} deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}