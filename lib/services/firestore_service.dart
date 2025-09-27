import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  // Generic CRUD operations
  Future<void> createDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).set(data);
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      AppLogger.info('DEBUG: FirestoreService deleteDocument called for collection: $collection, docId: $docId');
      await _db.collection(collection).doc(docId).delete();
      AppLogger.info('DEBUG: FirestoreService deleteDocument completed for collection: $collection, docId: $docId');
    } catch (e) {
      AppLogger.error('DEBUG: FirestoreService deleteDocument failed for collection: $collection, docId: $docId, error: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String collection, String docId) async {
    try {
      return await _db.collection(collection).doc(docId).get();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDocuments(
    String collection, {
    int? limit,
    DocumentSnapshot? startAfter,
    List<QueryOrder>? orderBy,
    List<QueryFilter>? where,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collection);

      // Apply where conditions
      if (where != null) {
        for (final filter in where) {
          query = query.where(filter.field, isEqualTo: filter.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchDocuments(
    String collection, {
    int? limit,
    List<QueryOrder>? orderBy,
    List<QueryFilter>? where,
  }) {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collection);

      // Apply where conditions
      if (where != null) {
        for (final filter in where) {
          query = query.where(filter.field, isEqualTo: filter.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots(includeMetadataChanges: true).map((snapshot) => snapshot.docs);
    } catch (e) {
      throw Exception('Failed to watch documents: $e');
    }
  }

  // Transaction helpers
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) action) async {
    try {
      return await _db.runTransaction(action);
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  // Batch operations
  WriteBatch batch() => _db.batch();

  // Search helpers
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchDocuments(
    String collection,
    String field,
    String searchTerm, {
    int? limit,
    List<QueryOrder>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collection);

      // For text search, we'll use array-contains for tags or simple equality
      // For more complex search, consider using Algolia or similar
      if (field == 'tags') {
        query = query.where(field, arrayContains: searchTerm.toLowerCase());
      } else {
        // Simple case-insensitive search (limited by Firestore)
        query = query.where(field, isGreaterThanOrEqualTo: searchTerm)
                    .where(field, isLessThan: '$searchTerm\uf8ff');
      }

      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }
}

// Helper classes for query building
class QueryOrder {
  final String field;
  final bool descending;

  const QueryOrder({required this.field, this.descending = false});
}

class QueryFilter {
  final String field;
  final dynamic value;

  const QueryFilter({required this.field, required this.value});
}