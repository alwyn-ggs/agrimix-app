import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditActionType {
  userLogin,
  userLogout,
  userRegistration,
  userUpdate,
  userDelete,
  postCreate,
  postUpdate,
  postDelete,
  commentCreate,
  commentUpdate,
  commentDelete,
  recipeCreate,
  recipeUpdate,
  recipeDelete,
  fermentationLogCreate,
  fermentationLogUpdate,
  fermentationLogDelete,
  violationReport,
  violationDismiss,
  violationWarn,
  violationDelete,
  violationBan,
  announcementCreate,
  announcementUpdate,
  announcementDelete,
  adminAction,
  systemAction,
}

class AuditLog {
  final String id;
  final String userId; // User who performed the action
  final String? targetUserId; // User affected by the action (if applicable)
  final AuditActionType actionType;
  final String actionDescription;
  final String? targetId; // ID of the affected resource
  final String? targetType; // Type of the affected resource
  final Map<String, dynamic>? metadata; // Additional data
  final String? reason; // Reason for the action
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final String? sessionId;

  AuditLog({
    required this.id,
    required this.userId,
    this.targetUserId,
    required this.actionType,
    required this.actionDescription,
    this.targetId,
    this.targetType,
    this.metadata,
    this.reason,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    this.sessionId,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      targetUserId: map['targetUserId'],
      actionType: AuditActionType.values.firstWhere(
        (e) => e.toString() == 'AuditActionType.${map['actionType']}',
        orElse: () => AuditActionType.systemAction,
      ),
      actionDescription: map['actionDescription'] ?? '',
      targetId: map['targetId'],
      targetType: map['targetType'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      reason: map['reason'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sessionId: map['sessionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'targetUserId': targetUserId,
      'actionType': actionType.toString().split('.').last,
      'actionDescription': actionDescription,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
      'reason': reason,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionId': sessionId,
    };
  }

  AuditLog copyWith({
    String? id,
    String? userId,
    String? targetUserId,
    AuditActionType? actionType,
    String? actionDescription,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
    String? reason,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    String? sessionId,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      actionType: actionType ?? this.actionType,
      actionDescription: actionDescription ?? this.actionDescription,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      metadata: metadata ?? this.metadata,
      reason: reason ?? this.reason,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  String toString() {
    return 'AuditLog(id: $id, userId: $userId, actionType: $actionType, actionDescription: $actionDescription, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
