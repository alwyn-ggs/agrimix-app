import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../models/post.dart';
import 'post_detail_page.dart';
import 'new_post_page.dart';
 
 

class PostListPage extends StatefulWidget {
  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final provider = context.read<CommunityProvider>();
      if (!provider.isLoadingPosts && provider.hasMorePosts) {
        provider.loadPosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                if (provider.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_isSearching && provider.searchResults.isEmpty) {
                  return _buildEmptySearch();
                }

                final posts = _isSearching ? provider.searchResults : provider.posts;

                if (posts.isEmpty && !provider.isLoadingPosts) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadPosts(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: posts.length + (provider.hasMorePosts ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return PostCard(
                        post: posts[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(post: posts[index]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewPostPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NatureColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search posts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                        });
                        context.read<CommunityProvider>().clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NatureColors.mediumGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NatureColors.primaryGreen, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _isSearching = true;
                });
                context.read<CommunityProvider>().searchPosts(value);
              } else {
                setState(() {
                  _isSearching = false;
                });
                context.read<CommunityProvider>().clearSearch();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: NatureColors.mediumGray,
          ),
          SizedBox(height: 16),
          Text(
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              color: NatureColors.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              color: NatureColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            size: 64,
            color: NatureColors.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              color: NatureColors.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share something!',
            style: TextStyle(
              color: NatureColors.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewPostPage()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NatureColors.pureWhite,
            Color(0xFFFAFBFA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: NatureColors.textDark.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: NatureColors.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              NatureColors.primaryGreen,
                              NatureColors.lightGreen,
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            (post.ownerName?.isNotEmpty == true
                                ? post.ownerName![0]
                                : (post.ownerUid.isNotEmpty ? post.ownerUid[0] : 'U'))
                                .toUpperCase(),
                            style: const TextStyle(
                              color: NatureColors.pureWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.ownerName?.isNotEmpty == true ? post.ownerName! : post.ownerUid,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NatureColors.darkGray,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: NatureColors.lightGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(post.createdAt),
                                style: const TextStyle(
                                  color: NatureColors.mediumGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final currentUser = authProvider.currentUser;
                      final isOwner = currentUser != null && post.ownerUid == currentUser.uid;
                      
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'report') {
                            _showReportDialog(context);
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, post.id);
                          }
                        },
                        itemBuilder: (context) => [
                          if (isOwner) ...[
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                          ],
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
                  const SizedBox(height: 16),
                  
                  // Enhanced Post Content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NatureColors.primaryGreen.withValues(alpha: 0.03),
                          NatureColors.lightGreen.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NatureColors.lightGreen.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Title
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: NatureColors.darkGray,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Enhanced Body preview
                        Text(
                          post.body,
                          style: const TextStyle(
                            color: NatureColors.darkGray,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 12),
              
                  // Enhanced Images preview
                  if (post.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: NatureColors.lightGreen.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.images.length > 3 ? 3 : post.images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(
                                left: index == 0 ? 0 : 8,
                                right: index == (post.images.length > 3 ? 3 : post.images.length) - 1 ? 0 : 8,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: NatureColors.textDark.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    post.images[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              NatureColors.lightGray,
                                              NatureColors.mediumGray,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: NatureColors.pureWhite,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
              
              
              // Actions
              Row(
                children: [
                  Consumer<CommunityProvider>(
                    builder: (context, provider, child) {
                      final currentUser = context.read<AuthProvider>().currentUser;
                      final isLiked = provider.isPostLiked(post.id, currentUser?.uid ?? '');
                      final latest = provider.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : NatureColors.mediumGray,
                            ),
                            onPressed: currentUser == null
                                ? null
                                : () {
                                    if (isLiked) {
                                      // prevent duplicate like
                                      return;
                                    }
                                    provider.likePost(post.id, currentUser.uid);
                                  },
                          ),
                          Text(
                            '${latest.likes}',
                            style: const TextStyle(color: NatureColors.mediumGray),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Consumer<CommunityProvider>(
                    builder: (context, provider, child) {
                      final currentUser = context.read<AuthProvider>().currentUser;
                      final isSaved = provider.isPostSaved(post.id, currentUser?.uid ?? '');
                      
                      return IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? NatureColors.primaryGreen : NatureColors.mediumGray,
                        ),
                        onPressed: () {
                          if (currentUser != null) {
                            if (isSaved) {
                              provider.unsavePost(post.id, currentUser.uid);
                            } else {
                              provider.savePost(post.id, currentUser.uid);
                            }
                          }
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: NatureColors.mediumGray),
                    onPressed: onTap,
                  ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(value: 'inappropriate', child: Text('Inappropriate content')),
                DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  final provider = context.read<CommunityProvider>();
                  final currentUser = context.read<AuthProvider>().currentUser;
                  if (currentUser != null) {
                    provider.reportPost(post.id, value, currentUser.uid);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post reported successfully')),
                    );
                    // Stay on page; only admins see reports in admin panel
                  }
                }
              },
            ),
          ],
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

  void _showDeleteDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              
              try {
                final provider = context.read<CommunityProvider>();
                final currentUser = context.read<AuthProvider>().currentUser;
                
                if (currentUser != null) {
                  await provider.deletePost(postId, currentUser.uid);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}