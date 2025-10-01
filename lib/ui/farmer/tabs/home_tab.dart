import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../router.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/announcement.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onTapBrowseRecipes;
  const HomeTab({super.key, this.onTapBrowseRecipes});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.currentAppUser?.name ?? 'Farmer';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NatureColors.primaryGreen,
                  Color(0xFF2E7D4F), // Darker green
                  NatureColors.lightGreen,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: NatureColors.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: NatureColors.primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern
                const Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.eco,
                      color: NatureColors.pureWhite,
                      size: 120,
                    ),
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NatureColors.pureWhite.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: NatureColors.pureWhite,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: NatureColors.offWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: NatureColors.pureWhite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: NatureColors.pureWhite.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🌱 Create, track, and share organic fertilizer recipes using FFJ and FPJ methods',
                          style: TextStyle(
                            fontSize: 14,
                            color: NatureColors.offWhite,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NatureColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.restaurant_menu,
                  title: 'Browse Recipes',
                  subtitle: 'Find what to make',
                  color: NatureColors.lightGreen,
                  onTap: () {
                    if (onTapBrowseRecipes != null) {
                      onTapBrowseRecipes!.call();
                    } else {
                      Navigator.of(context).pushNamed(Routes.recipes);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.bubble_chart,
                  title: 'Start Fermentation',
                  subtitle: 'Log a new batch',
                  color: NatureColors.accentGreen,
                  onTap: () => Navigator.of(context).pushNamed(Routes.newLog),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.groups,
                  title: 'New Post',
                  subtitle: 'Share with community',
                  color: NatureColors.primaryGreen,
                  onTap: () => Navigator.of(context).pushNamed(Routes.newPost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Announcements moved to notifications bell
          const SizedBox(height: 24),
          
          // My Recipes Quick Access
          const Text(
            'My Recipes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NatureColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.edit_note,
                  title: 'My Drafts',
                  subtitle: 'Continue working',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to My Recipes tab
                    // Note: This would ideally switch to the My Recipes tab and select drafts
                    // For now, just navigate to the tab
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.favorite,
                  title: 'Favorites',
                  subtitle: 'Liked recipes',
                  color: Colors.red,
                  onTap: () {
                    // Navigate to My Recipes tab
                    // Note: This would ideally switch to the My Recipes tab and select favorites
                    // For now, just navigate to the tab
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement announcement, {required bool isPinned}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPinned ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAnnouncementDetail(context, announcement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPinned 
                  ? NatureColors.primaryGreen.withAlpha((0.5 * 255).round())
                  : NatureColors.lightGray.withAlpha((0.3 * 255).round()),
              width: isPinned ? 2 : 1,
            ),
            color: isPinned 
                ? NatureColors.primaryGreen.withAlpha((0.05 * 255).round())
                : NatureColors.pureWhite,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPinned) ...[
                    const Icon(
                      Icons.push_pin,
                      color: NatureColors.primaryGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPinned ? NatureColors.primaryGreen : NatureColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: NatureColors.mediumGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: NatureColors.textDark,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: NatureColors.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'By ${announcement.createdBy}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NatureColors.mediumGray,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: NatureColors.mediumGray,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetail(BuildContext context, Announcement announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: NatureColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          if (announcement.pinned) ...[
                            const Icon(
                              Icons.push_pin,
                              color: NatureColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: NatureColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Meta info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: NatureColors.lightGray.withAlpha((0.3 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: NatureColors.mediumGray,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'By ${announcement.createdBy}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.mediumGray,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              color: NatureColors.mediumGray,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(announcement.createdAt),
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Content
                      Text(
                        announcement.body,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NatureColors.textDark,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAllAnnouncements(BuildContext context, List<Announcement> announcements) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('All Announcements'),
            backgroundColor: NatureColors.primaryGreen,
            foregroundColor: NatureColors.pureWhite,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return _buildAnnouncementCard(
                context,
                announcement,
                isPinned: announcement.pinned,
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha((0.25 * 255).round()), width: 1),
          color: NatureColors.pureWhite,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: NatureColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: NatureColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: NatureColors.mediumGray,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

}