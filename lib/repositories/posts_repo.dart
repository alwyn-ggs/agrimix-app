import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/post.dart';

class PostsRepo {
  final FirestoreService _fs;
  final StorageService _storage;

  PostsRepo(this._fs, this._storage);

  // CRUD Operations
  Future<void> createPost(Post post) async {
    try {
      await _fs.createDocument(Post.collectionPath, post.id, post.toMap());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _fs.getDocument(Post.collectionPath, postId);
      if (doc.exists) {
        return Post.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  Future<void> updatePost(Post post) async {
    try {
      await _fs.updateDocument(Post.collectionPath, post.id, post.toMap());
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _fs.deleteDocument(Post.collectionPath, postId);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Pagination
  Future<List<Post>> getPosts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? ownerUid,
    List<String>? tags,
  }) async {
    try {
      final where = <QueryFilter>[];
      if (ownerUid != null) where.add(QueryFilter(field: 'ownerUid', value: ownerUid));

      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: limit,
        startAfter: startAfter,
        where: where,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      var posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        posts = posts.where((post) => 
          post.tags.any((tag) => tags.contains(tag))
        ).toList();
      }

      return posts;
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // Real-time streams
  Stream<List<Post>> watchPosts({
    int? limit,
    String? ownerUid,
    List<String>? tags,
  }) {
    try {
      final where = <QueryFilter>[];
      if (ownerUid != null) where.add(QueryFilter(field: 'ownerUid', value: ownerUid));

      return _fs.watchDocuments(
        Post.collectionPath,
        limit: limit,
        where: where,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      ).map((docs) {
        var posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();

        // Filter by tags if provided
        if (tags != null && tags.isNotEmpty) {
          posts = posts.where((post) => 
            post.tags.any((tag) => tags.contains(tag))
          ).toList();
        }

        return posts;
      });
    } catch (e) {
      throw Exception('Failed to watch posts: $e');
    }
  }

  // Like/Unlike post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _fs.runTransaction((transaction) async {
        final postRef = _fs.db.collection(Post.collectionPath).doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentLikes = (postDoc.data()!['likes'] ?? 0) as int;
        transaction.update(postRef, {'likes': currentLikes + 1});
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _fs.runTransaction((transaction) async {
        final postRef = _fs.db.collection(Post.collectionPath).doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentLikes = (postDoc.data()!['likes'] ?? 0) as int;
        if (currentLikes > 0) {
          transaction.update(postRef, {'likes': currentLikes - 1});
        }
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Save/Unsave post
  Future<void> savePost(String postId, String userId) async {
    try {
      await _fs.runTransaction((transaction) async {
        final postRef = _fs.db.collection(Post.collectionPath).doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentSavedBy = List<String>.from(postDoc.data()!['savedBy'] ?? []);
        if (!currentSavedBy.contains(userId)) {
          currentSavedBy.add(userId);
          transaction.update(postRef, {'savedBy': currentSavedBy});
        }
      });
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  Future<void> unsavePost(String postId, String userId) async {
    try {
      await _fs.runTransaction((transaction) async {
        final postRef = _fs.db.collection(Post.collectionPath).doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentSavedBy = List<String>.from(postDoc.data()!['savedBy'] ?? []);
        currentSavedBy.remove(userId);
        transaction.update(postRef, {'savedBy': currentSavedBy});
      });
    } catch (e) {
      throw Exception('Failed to unsave post: $e');
    }
  }

  // Upload post images
  Future<List<String>> uploadPostImages(List<File> imageFiles, String userId) async {
    try {
      return await _storage.uploadFiles(
        files: imageFiles,
        userId: userId,
        folder: 'posts',
      );
    } catch (e) {
      throw Exception('Failed to upload post images: $e');
    }
  }

  // Search posts
  Future<List<Post>> searchPosts(String searchTerm, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: limit * 2, // Get more to filter
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      final posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter posts that contain the search term
      final filteredPosts = posts.where((post) => 
        post.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
        post.body.toLowerCase().contains(searchTerm.toLowerCase()) ||
        post.tags.any((tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()))
      ).take(limit).toList();

      return filteredPosts;
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // Get user's saved posts
  Future<List<Post>> getUserSavedPosts(String userId, {int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: limit * 2, // Get more to filter
        startAfter: startAfter,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      final posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter posts saved by the user
      return posts.where((post) => post.savedBy.contains(userId)).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get user saved posts: $e');
    }
  }

  // Get popular posts
  Future<List<Post>> getPopularPosts({int limit = 10}) async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'likes', descending: true)],
      );

      return docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get popular posts: $e');
    }
  }

  // Get posts by tag
  Future<List<Post>> getPostsByTag(String tag, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: limit * 2, // Get more to filter
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      final posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter posts that contain the tag
      return posts.where((post) => post.tags.contains(tag)).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get posts by tag: $e');
    }
  }

  // Get all tags
  Future<List<String>> getAllTags() async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: 1000, // Get many posts to extract tags
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      final posts = docs.map((doc) => Post.fromMap(doc.id, doc.data()!)).toList();
      final tags = <String>{};
      
      for (final post in posts) {
        tags.addAll(post.tags);
      }
      
      final tagList = tags.toList();
      tagList.sort();
      return tagList;
    } catch (e) {
      throw Exception('Failed to get all tags: $e');
    }
  }

  // Get post statistics
  Future<Map<String, int>> getPostStats(String userId) async {
    try {
      final posts = await getPosts(ownerUid: userId, limit: 1000);
      final stats = <String, int>{
        'total': posts.length,
        'totalLikes': posts.fold(0, (sum, post) => sum + post.likes),
        'totalSaved': posts.fold(0, (sum, post) => sum + post.savedBy.length),
      };
      return stats;
    } catch (e) {
      throw Exception('Failed to get post stats: $e');
    }
  }

  // Get last document for pagination
  Future<DocumentSnapshot?> getLastDocument() async {
    try {
      final docs = await _fs.getDocuments(
        Post.collectionPath,
        limit: 1,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );
      return docs.isNotEmpty ? docs.first : null;
    } catch (e) {
      throw Exception('Failed to get last document: $e');
    }
  }
}