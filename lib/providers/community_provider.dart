import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/posts_repo.dart';
import '../repositories/comments_repo.dart';
import '../repositories/violations_repo.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/violation.dart';

class CommunityProvider extends ChangeNotifier {
  final PostsRepo _postsRepo;
  final CommentsRepo _commentsRepo;
  final ViolationsRepo _violationsRepo;

  // State
  List<Post> posts = [];
  List<Post> savedPosts = [];
  List<Post> searchResults = [];
  List<Comment> comments = [];
  List<String> availableTags = [];
  List<Violation> violations = [];
  
  // Loading states
  bool isLoadingPosts = false;
  bool isLoadingComments = false;
  bool isLoadingSavedPosts = false;
  bool isSearching = false;
  bool isLoadingTags = false;
  
  // Pagination
  DocumentSnapshot? lastPostDoc;
  bool hasMorePosts = true;
  
  // Search and filters
  String currentSearchQuery = '';
  List<String> selectedTags = [];
  String sortBy = 'newest'; // newest, popular, oldest

  CommunityProvider(this._postsRepo, this._commentsRepo, this._violationsRepo) {
    _initialize();
  }

  // Getter for accessing posts repo from UI
  PostsRepo get postsRepo => _postsRepo;

  void _initialize() {
    // Watch posts stream
    _postsRepo.watchPosts(limit: 20).listen((v) { 
      posts = v; 
      notifyListeners(); 
    });
    
    // Load available tags
    loadTags();
  }

  // Posts
  Future<void> loadPosts({bool refresh = false}) async {
    if (isLoadingPosts) return;
    
    isLoadingPosts = true;
    notifyListeners();
    
    try {
      if (refresh) {
        lastPostDoc = null;
        hasMorePosts = true;
      }
      
      final newPosts = await _postsRepo.getPosts(
        limit: 20,
        startAfter: lastPostDoc,
        tags: selectedTags.isNotEmpty ? selectedTags : null,
      );
      
      if (refresh) {
        posts = newPosts;
      } else {
        posts.addAll(newPosts);
      }
      
      hasMorePosts = newPosts.length == 20;
      if (newPosts.isNotEmpty) {
        lastPostDoc = await _postsRepo.getLastDocument();
      }
      
    } catch (e) {
      debugPrint('Error loading posts: $e');
      // Prevent infinite loading loop on errors
      hasMorePosts = false;
    } finally {
      isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      currentSearchQuery = '';
      notifyListeners();
      return;
    }
    
    isSearching = true;
    currentSearchQuery = query;
    notifyListeners();
    
    try {
      searchResults = await _postsRepo.searchPosts(query);
    } catch (e) {
      debugPrint('Error searching posts: $e');
      searchResults = [];
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedPosts() async {
    if (isLoadingSavedPosts) return;
    
    isLoadingSavedPosts = true;
    notifyListeners();
    
    try {
      // This would need the current user ID - you'd get this from AuthProvider
      // For now, we'll use a placeholder
      savedPosts = await _postsRepo.getUserSavedPosts('current_user_id');
    } catch (e) {
      debugPrint('Error loading saved posts: $e');
    } finally {
      isLoadingSavedPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadTags() async {
    if (isLoadingTags) return;
    
    isLoadingTags = true;
    notifyListeners();
    
    try {
      availableTags = await _postsRepo.getAllTags();
    } catch (e) {
      debugPrint('Error loading tags: $e');
    } finally {
      isLoadingTags = false;
      notifyListeners();
    }
  }

  void setSelectedTags(List<String> tags) {
    selectedTags = tags;
    loadPosts(refresh: true);
  }

  void setSortBy(String sort) {
    sortBy = sort;
    loadPosts(refresh: true);
  }

  // Post actions
  Future<void> likePost(String postId, String userId) async {
    try {
      // Update local state first for immediate UI feedback
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentLikedBy = List<String>.from(posts[index].likedBy);
        if (!currentLikedBy.contains(userId)) {
          currentLikedBy.add(userId);
          posts[index] = posts[index].copyWith(
            likes: posts[index].likes + 1,
            likedBy: currentLikedBy,
          );
          notifyListeners();
        }
      }
      
      // Then update in database
      await _postsRepo.likePost(postId, userId);
    } catch (e) {
      debugPrint('Error liking post: $e');
      // Revert local changes if database update fails
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentLikedBy = List<String>.from(posts[index].likedBy);
        if (currentLikedBy.contains(userId)) {
          currentLikedBy.remove(userId);
          posts[index] = posts[index].copyWith(
            likes: posts[index].likes > 0 ? posts[index].likes - 1 : 0,
            likedBy: currentLikedBy,
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      // Update local state first for immediate UI feedback
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentLikedBy = List<String>.from(posts[index].likedBy);
        if (currentLikedBy.contains(userId)) {
          currentLikedBy.remove(userId);
          posts[index] = posts[index].copyWith(
            likes: posts[index].likes > 0 ? posts[index].likes - 1 : 0,
            likedBy: currentLikedBy,
          );
          notifyListeners();
        }
      }
      
      // Then update in database
      await _postsRepo.unlikePost(postId, userId);
    } catch (e) {
      debugPrint('Error unliking post: $e');
      // Revert local changes if database update fails
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentLikedBy = List<String>.from(posts[index].likedBy);
        if (!currentLikedBy.contains(userId)) {
          currentLikedBy.add(userId);
          posts[index] = posts[index].copyWith(
            likes: posts[index].likes + 1,
            likedBy: currentLikedBy,
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> savePost(String postId, String userId) async {
    try {
      // Update local state first for immediate UI feedback
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newSavedBy = List<String>.from(posts[index].savedBy);
        if (!newSavedBy.contains(userId)) {
          newSavedBy.add(userId);
          posts[index] = posts[index].copyWith(savedBy: newSavedBy);
          notifyListeners();
        }
      }
      
      // Then update in database
      await _postsRepo.savePost(postId, userId);
    } catch (e) {
      debugPrint('Error saving post: $e');
      // Revert local changes if database update fails
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newSavedBy = List<String>.from(posts[index].savedBy);
        newSavedBy.remove(userId);
        posts[index] = posts[index].copyWith(savedBy: newSavedBy);
        notifyListeners();
      }
    }
  }

  Future<void> unsavePost(String postId, String userId) async {
    try {
      // Update local state first for immediate UI feedback
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newSavedBy = List<String>.from(posts[index].savedBy);
        if (newSavedBy.contains(userId)) {
          newSavedBy.remove(userId);
          posts[index] = posts[index].copyWith(savedBy: newSavedBy);
          notifyListeners();
        }
      }
      
      // Then update in database
      await _postsRepo.unsavePost(postId, userId);
    } catch (e) {
      debugPrint('Error unsaving post: $e');
      // Revert local changes if database update fails
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newSavedBy = List<String>.from(posts[index].savedBy);
        newSavedBy.add(userId);
        posts[index] = posts[index].copyWith(savedBy: newSavedBy);
        notifyListeners();
      }
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
      // Check if user is the owner of the post
      final post = posts.firstWhere((p) => p.id == postId);
      if (post.ownerUid != userId) {
        throw Exception('You can only delete your own posts');
      }

      await _postsRepo.deletePost(postId);
      
      // Remove from local state
      posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow; // Re-throw to show error to user
    }
  }

  // Comments
  Future<void> loadComments(String postId) async {
    if (isLoadingComments) return;
    
    isLoadingComments = true;
    notifyListeners();
    
    try {
      comments = await _commentsRepo.getCommentsForPost(postId);
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      isLoadingComments = false;
      notifyListeners();
    }
  }

  Stream<List<Comment>> watchComments(String postId) {
    return _commentsRepo.watchCommentsForPost(postId);
  }

  Future<void> addComment(String postId, String userId, String text) async {
    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        authorId: userId,
        text: text,
        createdAt: DateTime.now(),
      );
      
      await _commentsRepo.createComment(comment);
      
      // Add comment to local state immediately for instant UI update
      comments.add(comment);
      notifyListeners();
      
      // Also reload comments to ensure consistency
      await loadComments(postId);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _commentsRepo.deleteComment(commentId);
      comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }

  // Violations/Reports
  Future<void> reportPost(String postId, String reason, String reporterId) async {
    try {
      final violation = Violation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        targetType: ViolationTargetType.post,
        targetId: postId,
        reason: reason,
        status: ViolationStatus.open,
        createdAt: DateTime.now(),
      );
      
      await _violationsRepo.createViolation(violation);
    } catch (e) {
      debugPrint('Error reporting post: $e');
    }
  }

  Future<void> loadViolations() async {
    try {
      violations = await _violationsRepo.getAllViolations();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading violations: $e');
    }
  }

  Stream<List<Violation>> watchViolations() {
    return _violationsRepo.watchViolations();
  }

  // Utility methods
  bool isPostLiked(String postId, String userId) {
    try {
      final post = posts.firstWhere((p) => p.id == postId);
      return post.likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  bool isPostSaved(String postId, String userId) {
    final post = posts.firstWhere((p) => p.id == postId, orElse: () => Post(
      id: '',
      ownerUid: '',
      title: '',
      body: '',
      images: [],
      tags: [],
      likes: 0,
      likedBy: [],
      savedBy: [],
      createdAt: DateTime.now(),
    ));
    return post.savedBy.contains(userId);
  }

  void clearSearch() {
    searchResults = [];
    currentSearchQuery = '';
    notifyListeners();
  }
}