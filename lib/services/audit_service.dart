import 'package:agrimix/models/audit_log.dart';
import 'package:agrimix/repositories/audit_repo.dart';
import '../utils/logger.dart';

class AuditService {
  final AuditRepo _auditRepo;

  AuditService(this._auditRepo);

  /// Log a user action with automatic context detection
  Future<void> logAction({
    required String userId,
    required AuditActionType actionType,
    required String actionDescription,
    String? targetUserId,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
    String? reason,
    String? sessionId,
  }) async {
    try {
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        targetUserId: targetUserId,
        actionType: actionType,
        actionDescription: actionDescription,
        targetId: targetId,
        targetType: targetType,
        metadata: metadata,
        reason: reason,
        ipAddress: await _getIpAddress(),
        userAgent: await _getUserAgent(),
        createdAt: DateTime.now(),
        sessionId: sessionId,
      );

      await _auditRepo.createAuditLog(auditLog);
    } catch (e) {
      // Log error but don't throw to avoid breaking the main flow
      AppLogger.error('Audit logging failed: $e', e);
    }
  }

  /// Log user authentication events
  Future<void> logUserLogin(String userId, {String? sessionId}) async {
    await logAction(
      userId: userId,
      actionType: AuditActionType.userLogin,
      actionDescription: 'User logged in',
      sessionId: sessionId,
    );
  }

  Future<void> logUserLogout(String userId, {String? sessionId}) async {
    await logAction(
      userId: userId,
      actionType: AuditActionType.userLogout,
      actionDescription: 'User logged out',
      sessionId: sessionId,
    );
  }

  Future<void> logUserRegistration(String userId, {Map<String, dynamic>? metadata}) async {
    await logAction(
      userId: userId,
      actionType: AuditActionType.userRegistration,
      actionDescription: 'User registered',
      metadata: metadata,
    );
  }

  /// Log user profile updates
  Future<void> logUserUpdate(String userId, String targetUserId, {
    Map<String, dynamic>? metadata,
    String? reason,
  }) async {
    await logAction(
      userId: userId,
      targetUserId: targetUserId,
      actionType: AuditActionType.userUpdate,
      actionDescription: 'User profile updated',
      targetId: targetUserId,
      targetType: 'user',
      metadata: metadata,
      reason: reason,
    );
  }

  /// Log content creation
  Future<void> logContentCreate(String userId, String targetType, String targetId, {
    Map<String, dynamic>? metadata,
  }) async {
    final actionType = _getContentActionType(targetType, true);
    await logAction(
      userId: userId,
      actionType: actionType,
      actionDescription: 'Created $targetType',
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
    );
  }

  /// Log content updates
  Future<void> logContentUpdate(String userId, String targetType, String targetId, {
    Map<String, dynamic>? metadata,
    String? reason,
  }) async {
    final actionType = _getContentActionType(targetType, false);
    await logAction(
      userId: userId,
      actionType: actionType,
      actionDescription: 'Updated $targetType',
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
      reason: reason,
    );
  }

  /// Log content deletion
  Future<void> logContentDelete(String userId, String targetType, String targetId, {
    Map<String, dynamic>? metadata,
    String? reason,
  }) async {
    final actionType = _getContentDeleteActionType(targetType);
    await logAction(
      userId: userId,
      actionType: actionType,
      actionDescription: 'Deleted $targetType',
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
      reason: reason,
    );
  }

  /// Log moderation actions
  Future<void> logViolationReport(String reporterId, String targetType, String targetId, {
    String? penalizedUserId,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    await logAction(
      userId: reporterId,
      targetUserId: penalizedUserId,
      actionType: AuditActionType.violationReport,
      actionDescription: 'Reported $targetType for violation',
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
      reason: reason,
    );
  }

  Future<void> logViolationDismiss(String adminId, String violationId, {
    String? reason,
  }) async {
    await logAction(
      userId: adminId,
      actionType: AuditActionType.violationDismiss,
      actionDescription: 'Dismissed violation report',
      targetId: violationId,
      targetType: 'violation',
      reason: reason,
    );
  }

  Future<void> logViolationWarn(String adminId, String targetUserId, String violationId, {
    String? reason,
  }) async {
    await logAction(
      userId: adminId,
      targetUserId: targetUserId,
      actionType: AuditActionType.violationWarn,
      actionDescription: 'Warned user for violation',
      targetId: violationId,
      targetType: 'violation',
      reason: reason,
    );
  }

  Future<void> logViolationDelete(String adminId, String targetType, String targetId, String targetUserId, {
    String? reason,
  }) async {
    await logAction(
      userId: adminId,
      targetUserId: targetUserId,
      actionType: AuditActionType.violationDelete,
      actionDescription: 'Deleted content due to violation',
      targetId: targetId,
      targetType: targetType,
      reason: reason,
    );
  }

  Future<void> logViolationBan(String adminId, String targetUserId, {
    String? reason,
    DateTime? banExpiresAt,
  }) async {
    await logAction(
      userId: adminId,
      targetUserId: targetUserId,
      actionType: AuditActionType.violationBan,
      actionDescription: 'Banned user',
      targetId: targetUserId,
      targetType: 'user',
      reason: reason,
      metadata: banExpiresAt != null ? {'banExpiresAt': banExpiresAt.toIso8601String()} : null,
    );
  }

  /// Log admin actions
  Future<void> logAdminAction(String adminId, String actionDescription, {
    String? targetId,
    String? targetType,
    String? targetUserId,
    Map<String, dynamic>? metadata,
    String? reason,
  }) async {
    await logAction(
      userId: adminId,
      targetUserId: targetUserId,
      actionType: AuditActionType.adminAction,
      actionDescription: actionDescription,
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
      reason: reason,
    );
  }

  /// Log system actions
  Future<void> logSystemAction(String actionDescription, {
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
  }) async {
    await logAction(
      userId: 'system',
      actionType: AuditActionType.systemAction,
      actionDescription: actionDescription,
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
    );
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getUserAuditLogs(String userId, {int limit = 50}) async {
    return await _auditRepo.getUserAuditLogs(userId, limit: limit);
  }

  /// Get audit logs for a specific target
  Future<List<AuditLog>> getTargetAuditLogs(String targetId, {int limit = 50}) async {
    return await _auditRepo.getTargetAuditLogs(targetId, limit: limit);
  }

  /// Get recent audit logs
  Future<List<AuditLog>> getRecentAuditLogs({int limit = 100}) async {
    return await _auditRepo.getRecentAuditLogs(limit: limit);
  }

  /// Get audit logs by action type
  Future<List<AuditLog>> getAuditLogsByAction(AuditActionType actionType, {int limit = 50}) async {
    return await _auditRepo.getAuditLogsByAction(actionType, limit: limit);
  }

  // Helper methods
  AuditActionType _getContentActionType(String targetType, bool isCreate) {
    switch (targetType.toLowerCase()) {
      case 'post':
        return isCreate ? AuditActionType.postCreate : AuditActionType.postUpdate;
      case 'comment':
        return isCreate ? AuditActionType.commentCreate : AuditActionType.commentUpdate;
      case 'recipe':
        return isCreate ? AuditActionType.recipeCreate : AuditActionType.recipeUpdate;
      case 'fermentation_log':
        return isCreate ? AuditActionType.fermentationLogCreate : AuditActionType.fermentationLogUpdate;
      case 'announcement':
        return isCreate ? AuditActionType.announcementCreate : AuditActionType.announcementUpdate;
      default:
        return isCreate ? AuditActionType.systemAction : AuditActionType.systemAction;
    }
  }

  AuditActionType _getContentDeleteActionType(String targetType) {
    switch (targetType.toLowerCase()) {
      case 'post':
        return AuditActionType.postDelete;
      case 'comment':
        return AuditActionType.commentDelete;
      case 'recipe':
        return AuditActionType.recipeDelete;
      case 'fermentation_log':
        return AuditActionType.fermentationLogDelete;
      case 'announcement':
        return AuditActionType.announcementDelete;
      default:
        return AuditActionType.systemAction;
    }
  }

  Future<String?> _getIpAddress() async {
    try {
      // This is a simplified approach - in a real app you might get this from headers
      return 'unknown';
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getUserAgent() async {
    try {
      // This is a simplified approach - in a real app you might get this from headers
      return 'AgriMix Mobile App';
    } catch (e) {
      return null;
    }
  }
}
