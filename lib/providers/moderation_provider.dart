import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/violations_repo.dart';
import '../repositories/posts_repo.dart';
import '../repositories/comments_repo.dart';
import '../services/notification_service.dart';
import '../models/violation.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../utils/logger.dart';

class ModerationProvider extends ChangeNotifier {
  final ViolationsRepo _violationsRepo;
  final PostsRepo _postsRepo;
  final CommentsRepo _commentsRepo;
  final NotificationService _notificationService;

  List<Violation> _violations = [];
  List<Post> _reportedPosts = [];
  List<Comment> _reportedComments = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<Violation>>? _violationsSubscription;

  ModerationProvider(
    this._violationsRepo,
    this._postsRepo,
    this._commentsRepo,
    this._notificationService,
  ) {
    _startListeningToViolations();
  }

  @override
  void dispose() {
    _violationsSubscription?.cancel();
    super.dispose();
  }

  // Getters
  List<Violation> get violations => _violations;
  List<Violation> get openViolations => _violations.where((v) => v.status == ViolationStatus.open).toList();
  List<Violation> get resolvedViolations => _violations.where((v) => v.status == ViolationStatus.resolved).toList();
  List<Violation> get dismissedViolations => _violations.where((v) => v.status == ViolationStatus.dismissed).toList();
  List<Post> get reportedPosts => _reportedPosts;
  List<Comment> get reportedComments => _reportedComments;
  bool get loading => _loading;
  String? get error => _error;

  // Statistics
  int get totalViolations => _violations.length;
  int get openViolationsCount => openViolations.length;
  int get resolvedViolationsCount => resolvedViolations.length;
  int get dismissedViolationsCount => dismissedViolations.length;

  // Start listening to violations
  void _startListeningToViolations() {
    _loading = true;
    _error = null;
    notifyListeners();

    _violationsSubscription = _violationsRepo.watchViolations().listen(
      (violations) {
        _violations = violations;
        _loading = false;
        _error = null;
        notifyListeners();
        _loadReportedContent();
      },
      onError: (error) {
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // Load reported content (posts and comments)
  Future<void> _loadReportedContent() async {
    try {
      final postViolations = _violations.where((v) => v.targetType == ViolationTargetType.post).toList();
      final commentViolations = _violations.where((v) => v.targetType == ViolationTargetType.comment).toList();

      // Load reported posts
      final postIds = postViolations.map((v) => v.targetId).toList();
      _reportedPosts = [];
      for (final postId in postIds) {
        final post = await _postsRepo.getPost(postId);
        if (post != null) {
          _reportedPosts.add(post);
        }
      }

      // Load reported comments
      final commentIds = commentViolations.map((v) => v.targetId).toList();
      _reportedComments = [];
      for (final commentId in commentIds) {
        final comment = await _commentsRepo.getComment(commentId);
        if (comment != null) {
          _reportedComments.add(comment);
        }
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading reported content: $e', e);
    }
  }

  // Create a violation report
  Future<void> reportViolation({
    required ViolationTargetType targetType,
    required String targetId,
    required String reason,
    required String reporterUid,
    String? penalizedUserUid,
  }) async {
    try {
      final violation = Violation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        status: ViolationStatus.open,
        reporterUid: reporterUid,
        penalizedUserUid: penalizedUserUid,
        createdAt: DateTime.now(),
      );

      await _violationsRepo.createViolation(violation);
    } catch (e) {
      _error = 'Failed to report violation: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Dismiss a violation
  Future<void> dismissViolation(String violationId, String adminId, {String? reason}) async {
    try {
      final violation = _violations.firstWhere((v) => v.id == violationId);
      final updatedViolation = violation.copyWith(
        status: ViolationStatus.dismissed,
        adminId: adminId,
        actionTaken: ViolationAction.dismiss,
        actionReason: reason ?? 'Violation dismissed by admin',
        resolvedAt: DateTime.now(),
      );

      await _violationsRepo.updateViolation(updatedViolation);

      // Admin action completed
    } catch (e) {
      _error = 'Failed to dismiss violation: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Warn user
  Future<void> warnUser(String violationId, String adminId, {required String warningMessage}) async {
    try {
      final violation = _violations.firstWhere((v) => v.id == violationId);
      // Resolve penalized user if missing
      String? targetUserId = violation.penalizedUserUid;
      if (targetUserId == null || targetUserId.isEmpty) {
        try {
          switch (violation.targetType) {
            case ViolationTargetType.post:
              final post = await _postsRepo.getPost(violation.targetId);
              targetUserId = post?.ownerUid;
              break;
            case ViolationTargetType.comment:
              final comment = await _commentsRepo.getComment(violation.targetId);
              targetUserId = comment?.authorId;
              break;
            case ViolationTargetType.recipe:
              // TODO: implement recipe owner lookup if needed
              break;
            case ViolationTargetType.user:
              targetUserId = violation.targetId;
              break;
          }
        } catch (e) {
          AppLogger.error('Failed to resolve penalized user for violation $violationId: $e', e);
        }
      }
      final updatedViolation = violation.copyWith(
        status: ViolationStatus.resolved,
        adminId: adminId,
        actionTaken: ViolationAction.warn,
        actionReason: warningMessage,
        resolvedAt: DateTime.now(),
      );

      await _violationsRepo.updateViolation(updatedViolation);

      // Send notification to user
      if (targetUserId != null && targetUserId.isNotEmpty) {
        await _notificationService.sendWarningNotification(
          userId: targetUserId,
          warningMessage: warningMessage,
          violationId: violationId,
        );
      } else {
        AppLogger.error('No penalized user found for violation $violationId. Warning not delivered.');
      }

      // Admin action completed
    } catch (e) {
      _error = 'Failed to warn user: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete content
  Future<void> deleteContent(String violationId, String adminId, {required String reason}) async {
    try {
      final violation = _violations.firstWhere((v) => v.id == violationId);
      
      // Delete the actual content
      switch (violation.targetType) {
        case ViolationTargetType.post:
          await _postsRepo.deletePost(violation.targetId);
          break;
        case ViolationTargetType.comment:
          await _commentsRepo.deleteComment(violation.targetId);
          break;
        case ViolationTargetType.recipe:
          // Recipe deletion would be handled by recipes repo
          // For now, we'll just mark the violation as resolved
          break;
        case ViolationTargetType.user:
          // User deletion would be handled by users repo
          // For now, we'll just mark the violation as resolved
          break;
      }

      final updatedViolation = violation.copyWith(
        status: ViolationStatus.resolved,
        adminId: adminId,
        actionTaken: ViolationAction.delete,
        actionReason: reason,
        resolvedAt: DateTime.now(),
      );

      await _violationsRepo.updateViolation(updatedViolation);

      // Send notification to user
      if (violation.penalizedUserUid != null) {
        await _notificationService.sendContentDeletionNotification(
          userId: violation.penalizedUserUid!,
          reason: reason,
          contentType: violation.targetType.name,
          contentId: violation.targetId,
        );
      }

      // Admin action completed
    } catch (e) {
      _error = 'Failed to delete content: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Ban user temporarily
  Future<void> banUser(String violationId, String adminId, {required String reason, required Duration banDuration}) async {
    try {
      final violation = _violations.firstWhere((v) => v.id == violationId);
      final banExpiresAt = DateTime.now().add(banDuration);

      final updatedViolation = violation.copyWith(
        status: ViolationStatus.resolved,
        adminId: adminId,
        actionTaken: ViolationAction.ban,
        actionReason: reason,
        banExpiresAt: banExpiresAt,
        resolvedAt: DateTime.now(),
      );

      await _violationsRepo.updateViolation(updatedViolation);

      // Send notification to user
      if (violation.penalizedUserUid != null) {
        await _notificationService.sendAccountSuspensionNotification(
          userId: violation.penalizedUserUid!,
          reason: reason,
          banExpiresAt: banExpiresAt,
          banDurationDays: banDuration.inDays,
        );
      }

      // Admin action completed
    } catch (e) {
      _error = 'Failed to ban user: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Report violation and notify admins
  Future<void> reportViolationAndNotify({
    required ViolationTargetType targetType,
    required String targetId,
    required String reason,
    required String reporterUid,
    String? penalizedUserUid,
  }) async {
    try {
      // Create violation report
      await reportViolation(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        reporterUid: reporterUid,
        penalizedUserUid: penalizedUserUid,
      );

      // Notify admins about new violation
      await _notificationService.sendViolationReportNotification(
        violationId: DateTime.now().millisecondsSinceEpoch.toString(),
        targetType: targetType.name,
        targetId: targetId,
        reason: reason,
        reporterUid: reporterUid,
      );
    } catch (e) {
      _error = 'Failed to report violation: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get violation statistics
  Future<Map<String, int>> getViolationStats() async {
    try {
      return await _violationsRepo.getViolationStats();
    } catch (e) {
      _error = 'Failed to get violation stats: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Refresh violations
  Future<void> refreshViolations() async {
    _violationsSubscription?.cancel();
    _startListeningToViolations();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
