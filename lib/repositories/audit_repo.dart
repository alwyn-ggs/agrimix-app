import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrimix/models/audit_log.dart';
import 'package:agrimix/services/firestore_service.dart';

class AuditRepo {
  final FirestoreService _firestoreService;
  static const String _collection = 'audit_logs';

  AuditRepo(this._firestoreService);

  /// Create a new audit log entry
  Future<void> createAuditLog(AuditLog auditLog) async {
    try {
      await _firestoreService.createDocument(
        _collection,
        auditLog.id,
        auditLog.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to create audit log: $e');
    }
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getUserAuditLogs(String userId, {int limit = 50}) async {
    try {
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
        where: [QueryFilter(field: 'userId', value: userId)],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user audit logs: $e');
    }
  }

  /// Get audit logs for a specific target (post, comment, etc.)
  Future<List<AuditLog>> getTargetAuditLogs(String targetId, {int limit = 50}) async {
    try {
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
        where: [QueryFilter(field: 'targetId', value: targetId)],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get target audit logs: $e');
    }
  }

  /// Get recent audit logs across all users
  Future<List<AuditLog>> getRecentAuditLogs({int limit = 100}) async {
    try {
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent audit logs: $e');
    }
  }

  /// Get audit logs by action type
  Future<List<AuditLog>> getAuditLogsByAction(AuditActionType actionType, {int limit = 50}) async {
    try {
      final actionTypeString = actionType.toString().split('.').last;
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
        where: [QueryFilter(field: 'actionType', value: actionTypeString)],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get audit logs by action: $e');
    }
  }

  /// Get audit logs by date range
  Future<List<AuditLog>> getAuditLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 100,
  }) async {
    try {
      // Note: Firestore doesn't support range queries with multiple fields easily
      // This is a simplified implementation - for production, consider using composite indexes
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      // Filter by date range in memory (not ideal for large datasets)
      final filteredDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
      }).toList();

      return filteredDocs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get audit logs by date range: $e');
    }
  }

  /// Get audit logs for moderation actions
  Future<List<AuditLog>> getModerationAuditLogs({int limit = 50}) async {
    try {
      final moderationActions = [
        AuditActionType.violationReport,
        AuditActionType.violationDismiss,
        AuditActionType.violationWarn,
        AuditActionType.violationDelete,
        AuditActionType.violationBan,
      ];

      final List<AuditLog> allLogs = [];
      
      for (final actionType in moderationActions) {
        final logs = await getAuditLogsByAction(actionType, limit: limit);
        allLogs.addAll(logs);
      }

      // Sort by creation date descending
      allLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allLogs.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get moderation audit logs: $e');
    }
  }

  /// Get audit logs for admin actions
  Future<List<AuditLog>> getAdminAuditLogs({int limit = 50}) async {
    try {
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
        where: [QueryFilter(field: 'actionType', value: 'adminAction')],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admin audit logs: $e');
    }
  }

  /// Get audit logs for a specific session
  Future<List<AuditLog>> getSessionAuditLogs(String sessionId, {int limit = 50}) async {
    try {
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
        where: [QueryFilter(field: 'sessionId', value: sessionId)],
      );

      return docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get session audit logs: $e');
    }
  }

  /// Search audit logs by description
  Future<List<AuditLog>> searchAuditLogs(String searchTerm, {int limit = 50}) async {
    try {
      // Note: This is a simplified search. For better search functionality,
      // consider using Algolia or implementing full-text search
      final docs = await _firestoreService.getDocuments(
        _collection,
        limit: limit * 2, // Get more docs to filter
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      final allLogs = docs
          .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by search term in action description
      return allLogs
          .where((log) => log.actionDescription.toLowerCase().contains(searchTerm.toLowerCase()))
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to search audit logs: $e');
    }
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1); // Start of current month
      final end = endDate ?? now;

      final logs = await getAuditLogsByDateRange(start, end, limit: 1000);

      final stats = <String, dynamic>{
        'totalActions': logs.length,
        'actionsByType': <String, int>{},
        'actionsByUser': <String, int>{},
        'actionsByDay': <String, int>{},
        'moderationActions': 0,
        'adminActions': 0,
        'userActions': 0,
      };

      for (final log in logs) {
        // Count by action type
        final actionType = log.actionType.toString().split('.').last;
        stats['actionsByType'][actionType] = (stats['actionsByType'][actionType] ?? 0) + 1;

        // Count by user
        stats['actionsByUser'][log.userId] = (stats['actionsByUser'][log.userId] ?? 0) + 1;

        // Count by day
        final day = log.createdAt.toIso8601String().split('T')[0];
        stats['actionsByDay'][day] = (stats['actionsByDay'][day] ?? 0) + 1;

        // Count by category
        if (log.actionType.toString().contains('violation') || 
            log.actionType == AuditActionType.adminAction) {
          stats['moderationActions']++;
        } else if (log.actionType == AuditActionType.adminAction) {
          stats['adminActions']++;
        } else {
          stats['userActions']++;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get audit statistics: $e');
    }
  }
}
