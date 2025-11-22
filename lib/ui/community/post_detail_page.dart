import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/theme.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../models/recipe.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

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
    final recipeProvider = Provider.of<RecipeProvider>(context, listen:false);
    Recipe? recipe;
    if (widget.post.recipeId != null) {
      final matches = recipeProvider.items.where((r) => r.id == widget.post.recipeId);
      recipe = matches.isNotEmpty ? matches.first : null;
    }
    final isInformal = recipe != null && (!recipe.isStandard || recipe.ownerUid == widget.post.ownerUid);
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
                    (widget.post.ownerName?.isNotEmpty == true
                            ? widget.post.ownerName![0]
                            : (widget.post.ownerUid.isNotEmpty ? widget.post.ownerUid[0] : 'U'))
                        .toUpperCase(),
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
                        widget.post.ownerName?.isNotEmpty == true ? widget.post.ownerName! : widget.post.ownerUid,
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
            if (isInformal)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'This is an informal recipe shared by a user. Always exercise judgment and refer to official recipes when needed.',
                      style: TextStyle(color: Colors.orange[900]),
                    ))
                  ],
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
            if (recipe != null && recipe.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round())),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: NatureColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recipe Ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NatureColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map((ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: NatureColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ingredient.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: NatureColors.darkGray,
                              ),
                            ),
                          ),
                          Text(
                            '${ingredient.amount} ${ingredient.unit}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: NatureColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
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
                    final reaction = provider.getUserReaction(widget.post.id, currentUser?.uid ?? '');
                    final post = provider.posts.firstWhere(
                      (p) => p.id == widget.post.id,
                      orElse: () => widget.post,
                    );
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            reaction == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: reaction == 1 ? Colors.green : NatureColors.mediumGray,
                          ),
                          onPressed: currentUser == null
                              ? null
                              : () {
                                  if (reaction == 1) return;
                                  provider.reactPost(widget.post.id, currentUser.uid, 1);
                                },
                        ),
                        Text(
                          '${post.thumbsUp}',
                          style: const TextStyle(color: NatureColors.mediumGray),
                        ),
                        IconButton(
                          icon: Icon(
                            reaction == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                            color: reaction == -1 ? Colors.red : NatureColors.mediumGray,
                          ),
                          onPressed: currentUser == null
                              ? null
                              : () {
                                  if (reaction == -1) return;
                                  provider.reactPost(widget.post.id, currentUser.uid, -1);
                                },
                        ),
                        Text(
                          '${post.thumbsDown}',
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
    final provider = context.read<CommunityProvider>();
    return StreamBuilder<List<Comment>>(
      stream: provider.watchComments(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Failed to load comments',
                style: TextStyle(color: NatureColors.mediumGray, fontSize: 16),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final comments = snapshot.data ?? const <Comment>[];
        final hasData = comments.isNotEmpty;

        if (!hasData) {
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
                    'Comments (${comments.length})',
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
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
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
                    (comment.authorName?.isNotEmpty == true
                            ? comment.authorName![0]
                            : (comment.authorId.isNotEmpty ? comment.authorId[0] : 'U'))
                        .toUpperCase(),
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
                        comment.authorName?.isNotEmpty == true ? comment.authorName! : comment.authorId,
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
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'report') {
                      final currentUser = context.read<AuthProvider>().currentUser;
                      if (currentUser != null) {
                        String? reason = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            String selectedReason = 'Unrelated/Spam';
                            String custom = '';
                            return StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: const Text('Report Comment'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButton<String>(
                                      value: selectedReason,
                                      items: [
                                        'Unrelated/Spam',
                                        'Harassment',
                                        'Inappropriate',
                                        'Other',
                                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (v) => setState(() => selectedReason = v ?? 'Other'),
                                    ),
                                    if (selectedReason == 'Other') ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        decoration: const InputDecoration(hintText: 'Type reason...'),
                                        onChanged: (v) => custom = v,
                                      )
                                    ]
                                  ]
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, selectedReason == 'Other' ? custom : selectedReason), child: const Text('Report')),
                                ],
                              )
                            );
                          },
                        );
                        if (reason != null && reason.trim().isNotEmpty) {
                          await context.read<CommunityProvider>().reportComment(
                              comment.id, comment.postId, comment.authorId, reason.trim(), currentUser.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment reported')));
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag,size:16), SizedBox(width:8), Text('Report')]))
                  ],
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
          _isSendingComment
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
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

  Future<void> _addComment(String text) async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      setState(() { _isSendingComment = true; });
      try {
        await context.read<CommunityProvider>().addComment(
          widget.post.id,
          currentUser.uid,
          text,
          authorName: auth.currentAppUser?.name,
        );
        _commentController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send comment: $e')),
          );
        }
      } finally {
        if (mounted) setState(() { _isSendingComment = false; });
      }
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