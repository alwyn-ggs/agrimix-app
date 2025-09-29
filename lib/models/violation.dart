import 'package:cloud_firestore/cloud_firestore.dart';

enum ViolationTargetType { post, recipe, user, comment }
enum ViolationStatus { open, resolved, dismissed }
enum ViolationAction { dismiss, warn, delete, ban }

class Violation {
  final String id;
  final ViolationTargetType targetType;
  final String targetId;
  final String reason;
  final ViolationStatus status;
  final String? penalizedUserUid;
  final String? reporterUid;
  final String? adminId;
  final ViolationAction? actionTaken;
  final String? actionReason;
  final DateTime? banExpiresAt;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Violation({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    this.penalizedUserUid,
    this.reporterUid,
    this.adminId,
    this.actionTaken,
    this.actionReason,
    this.banExpiresAt,
    required this.createdAt,
    this.resolvedAt,
  });

  static const String collectionPath = 'violations';
  static String docPath(String id) => 'violations/$id';

  factory Violation.fromMap(String id, Map<String, dynamic> map) => Violation(
        id: id,
        targetType: (() {
          final s = (map['targetType'] ?? '').toString();
          switch (s) {
            case 'recipe':
              return ViolationTargetType.recipe;
            case 'user':
              return ViolationTargetType.user;
            case 'comment':
              return ViolationTargetType.comment;
            default:
              return ViolationTargetType.post;
          }
        })(),
        targetId: map['targetId'] ?? map['postId'] ?? '',
        reason: map['reason'] ?? '',
        status: (() {
          final s = (map['status'] ?? 'open').toString();
          switch (s) {
            case 'resolved':
              return ViolationStatus.resolved;
            case 'dismissed':
              return ViolationStatus.dismissed;
            default:
              return ViolationStatus.open;
          }
        })(),
        penalizedUserUid: map['penalizedUserUid'],
        reporterUid: map['reporterUid'],
        adminId: map['adminId'],
        actionTaken: map['actionTaken'] != null ? (() {
          final s = map['actionTaken'].toString();
          switch (s) {
            case 'warn':
              return ViolationAction.warn;
            case 'delete':
              return ViolationAction.delete;
            case 'ban':
              return ViolationAction.ban;
            default:
              return ViolationAction.dismiss;
          }
        })() : null,
        actionReason: map['actionReason'],
        banExpiresAt: map['banExpiresAt'] is Timestamp ? (map['banExpiresAt'] as Timestamp).toDate() : null,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        resolvedAt: map['resolvedAt'] is Timestamp ? (map['resolvedAt'] as Timestamp).toDate() : null,
      );

  factory Violation.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Violation.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'targetType': () {
          switch (targetType) {
            case ViolationTargetType.recipe:
              return 'recipe';
            case ViolationTargetType.user:
              return 'user';
            case ViolationTargetType.comment:
              return 'comment';
            case ViolationTargetType.post:
              return 'post';
          }
        }(),
        'targetId': targetId,
        'reason': reason,
        'status': () {
          switch (status) {
            case ViolationStatus.resolved:
              return 'resolved';
            case ViolationStatus.dismissed:
              return 'dismissed';
            case ViolationStatus.open:
              return 'open';
          }
        }(),
        'penalizedUserUid': penalizedUserUid,
        'reporterUid': reporterUid,
        'adminId': adminId,
        'actionTaken': actionTaken?.name,
        'actionReason': actionReason,
        'banExpiresAt': banExpiresAt != null ? Timestamp.fromDate(banExpiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      };

  Violation copyWith({
    ViolationTargetType? targetType,
    String? targetId,
    String? reason,
    ViolationStatus? status,
    String? penalizedUserUid,
    String? reporterUid,
    String? adminId,
    ViolationAction? actionTaken,
    String? actionReason,
    DateTime? banExpiresAt,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) => Violation(
        id: id,
        targetType: targetType ?? this.targetType,
        targetId: targetId ?? this.targetId,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        penalizedUserUid: penalizedUserUid ?? this.penalizedUserUid,
        reporterUid: reporterUid ?? this.reporterUid,
        adminId: adminId ?? this.adminId,
        actionTaken: actionTaken ?? this.actionTaken,
        actionReason: actionReason ?? this.actionReason,
        banExpiresAt: banExpiresAt ?? this.banExpiresAt,
        createdAt: createdAt ?? this.createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );
}