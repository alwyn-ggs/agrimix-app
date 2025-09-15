import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/comment.dart';

class CommentsRepo {
  final FirestoreService _fs;

  CommentsRepo(this._fs);

  // CRUD Operations
  Future<void> createComment(Comment comment) async {
    try {
      await _fs.createDocument(Comment.collectionPath, comment.id, comment.toMap());
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  Future<Comment?> getComment(String commentId) async {
    try {
      final doc = await _fs.getDocument(Comment.collectionPath, commentId);
      if (doc.exists) {
        return Comment.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get comment: $e');
    }
  }

  Future<void> updateComment(Comment comment) async {
    try {
      await _fs.updateDocument(Comment.collectionPath, comment.id, comment.toMap());
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _fs.deleteDocument(Comment.collectionPath, commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get comments for a post
  Future<List<Comment>> getCommentsForPost(String postId, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Comment.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'postId', value: postId)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: false)],
      );

      return docs.map((doc) => Comment.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get comments for post: $e');
    }
  }

  // Watch comments for a post (real-time)
  Stream<List<Comment>> watchCommentsForPost(String postId, {int limit = 50}) {
    try {
      return _fs.watchDocuments(
        Comment.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'postId', value: postId)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: false)],
      ).map((docs) => docs.map((doc) => Comment.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch comments for post: $e');
    }
  }

  // Get user's comments
  Future<List<Comment>> getUserComments(String userId, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Comment.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'authorId', value: userId)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Comment.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get user comments: $e');
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final docs = await _fs.getDocuments(
        Comment.collectionPath,
        where: [QueryFilter(field: 'postId', value: postId)],
      );

      return docs.length;
    } catch (e) {
      throw Exception('Failed to get comment count: $e');
    }
  }
}
