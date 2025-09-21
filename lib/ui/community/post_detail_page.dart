import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../models/post.dart';
import '../../models/comment.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPostContent(),
                  const Divider(),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: NatureColors.primaryGreen,
                  child: Text(
                    widget.post.ownerUid.isNotEmpty ? widget.post.ownerUid[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: NatureColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.ownerUid,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: NatureColors.darkGray,
                        ),
                      ),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: const TextStyle(
                          color: NatureColors.mediumGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NatureColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.body,
              style: const TextStyle(
                color: NatureColors.darkGray,
                height: 1.5,
                fontSize: 16,
              ),
            ),
            if (widget.post.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.post.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.post.images[index],
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: NatureColors.lightGray,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    final currentUser = context.read<AuthProvider>().currentUser;
                    final isLiked = provider.isPostLiked(widget.post.id, currentUser?.uid ?? '');
                    
                    return IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : NatureColors.mediumGray,
                      ),
                      onPressed: () {
                        if (currentUser != null) {
                          if (isLiked) {
                            provider.unlikePost(widget.post.id, currentUser.uid);
                          } else {
                            provider.likePost(widget.post.id, currentUser.uid);
                          }
                        }
                      },
                    );
                  },
                ),
                Text(
                  '${widget.post.likes}',
                  style: const TextStyle(color: NatureColors.mediumGray),
                ),
                const SizedBox(width: 16),
                Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    final currentUser = context.read<AuthProvider>().currentUser;
                    final isSaved = provider.isPostSaved(widget.post.id, currentUser?.uid ?? '');
                    
                    return IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? NatureColors.primaryGreen : NatureColors.mediumGray,
                      ),
                      onPressed: () {
                        if (currentUser != null) {
                          if (isSaved) {
                            provider.unsavePost(widget.post.id, currentUser.uid);
                          } else {
                            provider.savePost(widget.post.id, currentUser.uid);
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingComments) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(
                  color: NatureColors.mediumGray,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Comments (${provider.comments.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NatureColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.comments.length,
              itemBuilder: (context, index) {
                final comment = provider.comments[index];
                return _buildCommentItem(comment);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: NatureColors.lightGreen,
                  child: Text(
                    comment.authorId.isNotEmpty ? comment.authorId[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: NatureColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: NatureColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(
                          color: NatureColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: const TextStyle(
                color: NatureColors.darkGray,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addComment(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_commentController.text.trim().isNotEmpty) {
                _addComment(_commentController.text.trim());
              }
            },
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: NatureColors.primaryGreen,
              foregroundColor: NatureColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  void _addComment(String text) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser != null) {
      context.read<CommunityProvider>().addComment(widget.post.id, currentUser.uid, text);
      _commentController.clear();
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
}