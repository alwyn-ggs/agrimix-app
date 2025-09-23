import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/moderation_provider.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../theme/theme.dart';

class CommunityModerationPage extends StatefulWidget {
  const CommunityModerationPage({super.key, required int initialTabIndex});

  @override
  State<CommunityModerationPage> createState() => _CommunityModerationPageState();
}

class _CommunityModerationPageState extends State<CommunityModerationPage> with TickerProviderStateMixin {
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
    final communityProvider = context.read<CommunityProvider>();
    final moderationProvider = context.read<ModerationProvider>();
    
    // Load posts and comments
    communityProvider.loadPosts(refresh: true);
    // Note: loadComments requires a postId, so we'll load comments for all posts
    for (final post in communityProvider.posts) {
      communityProvider.loadComments(post.id);
    }
    
    // Load violations
    moderationProvider.refreshViolations();
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
        title: const Text('Community Moderation'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: NatureColors.pureWhite,
          unselectedLabelColor: NatureColors.lightGray,
          indicatorColor: NatureColors.pureWhite,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 24),
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Posts'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.report_problem_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Reports'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, communityProvider, child) {
        if (communityProvider.isLoadingPosts) {
          return const Center(child: CircularProgressIndicator());
        }

        if (communityProvider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article_outlined, size: 64, color: NatureColors.lightGray),
                const SizedBox(height: 16),
                const Text(
                  'No posts found',
                  style: TextStyle(
                    fontSize: 18,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading: ${communityProvider.isLoadingPosts}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communityProvider.posts.length,
          itemBuilder: (context, index) {
            final post = communityProvider.posts[index];
            return _buildPostCard(post);
          },
        );
      },
    );
  }

  Widget buildCommentsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, communityProvider, child) {
        if (communityProvider.isLoadingComments) {
          return const Center(child: CircularProgressIndicator());
        }

        if (communityProvider.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.comment_outlined, size: 64, color: NatureColors.lightGray),
                const SizedBox(height: 16),
                const Text(
                  'No comments found',
                  style: TextStyle(
                    fontSize: 18,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading: ${communityProvider.isLoadingComments}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communityProvider.comments.length,
          itemBuilder: (context, index) {
            final comment = communityProvider.comments[index];
            return _buildCommentCard(comment);
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return Consumer<ModerationProvider>(
      builder: (context, moderationProvider, child) {
        if (moderationProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (moderationProvider.violations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.report_problem_outlined, size: 64, color: NatureColors.lightGray),
                const SizedBox(height: 16),
                const Text(
                  'No reports found',
                  style: TextStyle(
                    fontSize: 18,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading: ${moderationProvider.loading}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NatureColors.lightGray,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: moderationProvider.violations.length,
          itemBuilder: (context, index) {
            final violation = moderationProvider.violations[index];
            return _buildViolationCard(violation);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (post.ownerName != null && post.ownerName!.trim().isNotEmpty)
                            ? post.ownerName!
                            : 'User ${post.ownerUid.isNotEmpty ? post.ownerUid.substring(0, post.ownerUid.length.clamp(0, 8)) : 'unknown'}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(
                          color: NatureColors.lightGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePostAction(value, post),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: const TextStyle(fontSize: 14),
            ),
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (context, idx) {
                        final url = post.images[idx];
                        return Container(
                          margin: EdgeInsets.only(right: idx == post.images.length - 1 ? 0 : 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 200,
                                color: NatureColors.lightGray,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${post.images.length} images',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Likes and live comment count
            StreamBuilder<List<Comment>>(
              stream: context.read<CommunityProvider>().watchComments(post.id),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: post.likes > 0 ? Colors.red : NatureColors.lightGray,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likes}'),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.comment,
                      color: NatureColors.lightGray,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('$count'),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Expandable list of all comments for this post (no commenters chips)
            StreamBuilder<List<Comment>>(
              stream: context.read<CommunityProvider>().watchComments(post.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final comments = snapshot.data!;
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Comments (${comments.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  childrenPadding: const EdgeInsets.only(top: 8),
                  children: [
                    ListView.builder(
                      itemCount: comments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        final name = (c.authorName != null && c.authorName!.trim().isNotEmpty)
                            ? c.authorName!.trim()
                            : (c.authorId.isNotEmpty
                                ? 'User ${c.authorId.substring(0, c.authorId.length.clamp(0, 8))}...'
                                : 'Unknown');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(c.text, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (comment.authorName != null && comment.authorName!.trim().isNotEmpty)
                            ? comment.authorName!
                            : 'User ${comment.authorId.isNotEmpty ? comment.authorId.substring(0, comment.authorId.length.clamp(0, 8)) : 'unknown'}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(
                          color: NatureColors.lightGray,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCommentAction(value, comment),
                  itemBuilder: (context) => [
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationCard(dynamic violation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.report_problem,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reported ${violation.targetType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(violation.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    violation.status.toUpperCase(),
                    style: const TextStyle(
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
                color: NatureColors.lightGray,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleViolationAction('resolve', violation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Resolve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleViolationAction('dismiss', violation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
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

  void _handlePostAction(String action, Post post) {
    switch (action) {
      case 'view':
        // Navigate to post detail
        break;
      case 'delete':
        _showDeleteConfirmation(post.id, 'post');
        break;
    }
  }

  void _handleCommentAction(String action, Comment comment) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation(comment.id, 'comment');
        break;
    }
  }

  void _handleViolationAction(String action, dynamic violation) {
    final moderationProvider = context.read<ModerationProvider>();
    
    switch (action) {
      case 'resolve':
        // For now, we'll use dismissViolation with a reason
        moderationProvider.dismissViolation(violation.id, 'admin_id', reason: 'Resolved by admin');
        break;
      case 'dismiss':
        moderationProvider.dismissViolation(violation.id, 'admin_id', reason: 'Dismissed by admin');
        break;
    }
  }

  void showReportDialog(String contentId, String contentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report $contentType'),
        content: const Text('Are you sure you want to report this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle report
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$contentType reported successfully')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String contentId, String contentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $contentType'),
        content: Text('Are you sure you want to delete this $contentType? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle delete
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$contentType deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
