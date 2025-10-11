import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'messaging_service.dart';
import '../utils/logger.dart';

class NotificationService {
  final MessagingService _messagingService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._messagingService);

  bool _isInitialized = false;

  /// Ensure notification service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
      _isInitialized = true;
    }
  }

  /// Handle notification actions (when user taps on notification buttons)
  static void handleNotificationAction(String action, String payload) {
    switch (action) {
      case 'open_app':
        // Navigate to fermentation detail page
        AppLogger.info('User tapped "Open App" for payload: $payload');
        _navigateToNotificationBell();
        break;
      case 'mark_done':
        // Mark fermentation stage as completed
        AppLogger.info('User tapped "Mark as Done" for payload: $payload');
        _navigateToNotificationBell();
        break;
      case 'view_announcement':
        // Navigate to announcement details
        AppLogger.info('User tapped "View Details" for announcement: $payload');
        _navigateToNotificationBell();
        break;
      case 'mark_read':
        // Mark notification as read
        AppLogger.info('User tapped "Mark as Read" for payload: $payload');
        _navigateToNotificationBell();
        break;
      case 'view_report':
        // Navigate to report details
        AppLogger.info('User tapped "Review Report" for payload: $payload');
        _navigateToNotificationBell();
        break;
      case 'dismiss':
        // Dismiss notification
        AppLogger.info('User tapped "Dismiss" for payload: $payload');
        break;
      default:
        AppLogger.info('Unknown notification action: $action');
        _navigateToNotificationBell();
    }
  }

  /// Navigate to notification bell (this would be handled by your app's navigation)
  static void _navigateToNotificationBell() {
    // This would typically use your app's navigation system
    // For example: Navigator.pushNamed(context, '/notifications');
    AppLogger.info('Navigating to notification bell');
  }


  /// Normalize report reason for admin bell message
  String _normalizeReasonForAdminBell(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return 'a violation';
    final lower = trimmed.toLowerCase();
    if (lower.contains('harass')) return 'harassment';
    if (lower.contains('spam')) return 'spam';
    if (lower.contains('misleading')) return 'misleading information';
    if (lower.contains('inappropriate')) return 'inappropriate content';
    if (lower.contains('violence') || lower.contains('dangerous')) return 'violent or dangerous content';
    if (lower.contains('hate')) return 'hate speech';
    if (lower.contains('copyright')) return 'copyright violation';
    // Default: use user-provided reason as-is
    return trimmed;
  }

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Initialize timezone data
    // Initialize timezone data - this is done automatically in newer versions
    // tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    _isInitialized = true;
  }

  /// Send moderation notification to user
  Future<void> sendModerationNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM tokens
      final tokens = await _messagingService.getUserTokens(userId);
      
      if (tokens.isNotEmpty) {
        // In a real implementation, you would send FCM messages here
        // For now, we'll create a notification record in the database
        await _createNotificationRecord(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        
        AppLogger.info('Moderation notification sent to user $userId: $title - $body');
      }
    } catch (e) {
      AppLogger.error('Failed to send moderation notification: $e', e);
    }
  }

  /// Create notification record in database
  Future<void> _createNotificationRecord({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _db.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to create notification record: $e', e);
    }
  }

  /// Send warning notification
  Future<void> sendWarningNotification({
    required String userId,
    required String warningMessage,
    required String violationId,
  }) async {
    await sendModerationNotification(
      userId: userId,
      title: 'Community Warning',
      body: warningMessage,
      type: 'warning',
      data: {
        'violationId': violationId,
        'action': 'warning',
      },
    );
  }

  /// Send content deletion notification
  Future<void> sendContentDeletionNotification({
    required String userId,
    required String reason,
    required String contentType,
    required String contentId,
  }) async {
    await sendModerationNotification(
      userId: userId,
      title: 'Content Removed',
      body: 'Your $contentType has been removed due to: $reason',
      type: 'content_removed',
      data: {
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        'action': 'delete',
      },
    );
  }

  /// Send account suspension notification
  Future<void> sendAccountSuspensionNotification({
    required String userId,
    required String reason,
    required DateTime banExpiresAt,
    required int banDurationDays,
  }) async {
    await sendModerationNotification(
      userId: userId,
      title: 'Account Suspended',
      body: 'Your account has been temporarily suspended until ${banExpiresAt.toString().split(' ')[0]}. Reason: $reason',
      type: 'account_suspended',
      data: {
        'reason': reason,
        'banExpiresAt': banExpiresAt.toIso8601String(),
        'banDurationDays': banDurationDays,
        'action': 'ban',
      },
    );
  }

  /// Show local notification
  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'announcements',
        'Announcements',
        channelDescription: 'Notifications for announcements and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      AppLogger.error('Failed to show notification: $e', e);
    }
  }

  /// Send violation report notification to admins
  Future<void> sendViolationReportNotification({
    required String violationId,
    required String targetType,
    required String targetId,
    required String reason,
    required String reporterUid,
    String? penalizedUserUid,
  }) async {
    try {
      // Try to resolve reported user's display name
      String reportedName = 'User';
      try {
        final String? uid = penalizedUserUid;
        if (uid != null && uid.isNotEmpty) {
          final snap = await _db.collection('users').doc(uid).get();
          final data = snap.data();
          final name = (data?['name'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            reportedName = name;
          } else {
            // Shorten UID for readability
            reportedName = uid.length > 8 ? '${uid.substring(0, 8)}...' : uid;
          }
        }
      } catch (_) {}

      final String normalizedReason = _normalizeReasonForAdminBell(reason);
      final body = '$reportedName has been reported for $normalizedReason. Check your Community Dashboard.';

      // Get all admin users
      final adminQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final batch = _db.batch();
      for (final adminDoc in adminQuery.docs) {
        final adminId = adminDoc.id;
        final notifRef = _db
            .collection('users')
            .doc(adminId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': 'Community Report',
          'body': body,
          'type': 'violation_report',
          'data': {
            'violationId': violationId,
            'targetType': targetType,
            'targetId': targetId,
            'reason': reason,
            'reporterUid': reporterUid,
            'penalizedUserUid': penalizedUserUid,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to send violation report notification: $e', e);
    }
  }

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get user notifications: $e', e);
      return [];
    }
  }

  /// Send announcement notifications to all users
  Future<void> sendAnnouncementToAllUsers({
    required String title,
    required String body,
    required String announcementId,
  }) async {
    try {
      // Get current user to skip them
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;
      
      final usersSnap = await _db.collection('users').get();
      final batch = _db.batch();
      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data();
        final role = (data['role'] as String?)?.toLowerCase();
        final userId = userDoc.id;
        // Skip admins and current user: They should not receive their own announcements
        if (role == 'admin' || userId == currentUserId) {
          continue;
        }
        final notifRef = _db
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': 'Administration',
          'body': body,
          'type': 'announcement',
          'data': {
            'announcementId': announcementId,
            'action': 'announcement',
            'originalTitle': title,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Mark announcement as delivered to notifications to avoid duplicate fanouts
      try {
        await _db.collection('announcements').doc(announcementId).update({'pushSent': true});
      } catch (_) {}
    } catch (e) {
      AppLogger.error('Failed to send announcement notifications: $e', e);
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to clear notifications: $e', e);
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      AppLogger.error('Failed to mark notification as read: $e', e);
    }
  }

  /// Mark notification as unread
  Future<void> markNotificationAsUnread(String userId, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': false});
    } catch (e) {
      AppLogger.error('Failed to mark notification as unread: $e', e);
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      AppLogger.error('Failed to delete notification: $e', e);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read: $e', e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('Failed to get unread notification count: $e', e);
      return 0;
    }
  }

  /// Schedule fermentation notifications with enhanced tracking
  Future<void> scheduleFermentationNotifications(
    String logId,
    String title,
    List<Map<String, dynamic>> stages,
    DateTime startDate,
  ) async {
    try {
      // Ensure notification service is initialized
      await _ensureInitialized();
      
      // Schedule notifications for each stage
      for (int i = 0; i < stages.length; i++) {
        final stage = stages[i];
        final day = stage['day'] as int;
        final stageLabel = stage['label'] as String? ?? 'Stage ${i + 1}';
        final stageAction = stage['action'] as String? ?? '';
        final notificationDate = startDate.add(Duration(days: day));
         
        // Only schedule if the date is in the future
        if (notificationDate.isAfter(DateTime.now())) {
          AppLogger.info('Scheduling fermentation notification for $stageLabel at ${notificationDate.toString()}');
          
          // Schedule primary notification
          await _localNotifications.zonedSchedule(
            logId.hashCode + i, // Unique ID for each notification
            '🌱 Fermentation Time!',
            '$title\n\n$stageLabel: $stageAction\n\nTap to open the app and track your progress.',
            _convertToTZDateTime(notificationDate),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'fermentation_channel',
                'Fermentation Notifications',
                channelDescription: 'Important reminders for your fermentation process',
                importance: Importance.max,
                priority: Priority.max,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
                enableLights: true,
                ledColor: const Color(0xFF4CAF50),
                ledOnMs: 1000,
                ledOffMs: 500,
                showWhen: true,
                when: null,
                usesChronometer: false,
                playSound: true,
                category: AndroidNotificationCategory.reminder,
                actions: const [
                  AndroidNotificationAction(
                    'open_app',
                    'Open App',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'mark_done',
                    'Mark as Done',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'snooze_1h',
                    'Snooze 1h',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
                categoryIdentifier: 'FERMENTATION_REMINDER',
                threadIdentifier: 'fermentation_$logId',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'fermentation:$logId:$i:primary',
          );

          // Schedule follow-up notifications for users who don't actively use the app
          await _scheduleFollowUpNotifications(logId, i, stageLabel, notificationDate, title);
        } else {
          AppLogger.warning('Skipping fermentation notification for $stageLabel - date is in the past: ${notificationDate.toString()}');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to schedule fermentation notifications: $e', e);
    }
  }

  /// Schedule follow-up notifications for inactive users
  Future<void> _scheduleFollowUpNotifications(
    String logId,
    int stageIndex,
    String stageLabel,
    DateTime notificationDate,
    String title,
  ) async {
    try {
      // Schedule follow-up notifications at strategic intervals
      final followUpTimes = [
        const Duration(hours: 2),   // 2 hours after
        const Duration(hours: 6),   // 6 hours after
        const Duration(days: 1),    // 1 day after
        const Duration(days: 2),    // 2 days after
        const Duration(days: 3),    // 3 days after
      ];

      for (int i = 0; i < followUpTimes.length; i++) {
        final followUpDate = notificationDate.add(followUpTimes[i]);
        
        if (followUpDate.isAfter(DateTime.now())) {
          await _localNotifications.zonedSchedule(
            logId.hashCode + stageIndex + 1000 + i, // Unique ID for follow-up
            _getFollowUpTitle(i),
            _getFollowUpMessage(stageLabel, i, title),
            _convertToTZDateTime(followUpDate),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'fermentation_followup',
                'Fermentation Follow-ups',
                channelDescription: 'Follow-up reminders for fermentation stages',
                importance: i < 2 ? Importance.high : Importance.defaultImportance,
                priority: i < 2 ? Priority.high : Priority.defaultPriority,
                enableVibration: i < 2,
                vibrationPattern: i < 2 ? Int64List.fromList([0, 500, 250, 500]) : null,
                enableLights: i < 2,
                ledColor: i < 2 ? const Color(0xFFFF9800) : null,
                ledOnMs: i < 2 ? 1000 : null,
                ledOffMs: i < 2 ? 500 : null,
                showWhen: true,
                playSound: true,
                category: AndroidNotificationCategory.reminder,
                actions: const [
                  AndroidNotificationAction(
                    'open_app',
                    'Open App',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'mark_done',
                    'Mark as Done',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'dismiss',
                    'Dismiss',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
                categoryIdentifier: 'FERMENTATION_FOLLOWUP',
                threadIdentifier: 'fermentation_$logId',
                interruptionLevel: i < 2 ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
              ),
            ),
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'fermentation:$logId:$stageIndex:followup_$i',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to schedule follow-up notifications: $e', e);
    }
  }

  /// Get follow-up notification title based on escalation level
  String _getFollowUpTitle(int level) {
    switch (level) {
      case 0:
        return '⏰ Gentle Reminder';
      case 1:
        return '🔔 Don\'t Forget!';
      case 2:
        return '⚠️ Overdue Stage';
      case 3:
        return '🚨 Urgent: Fermentation Stage';
      case 4:
        return '🆘 Critical: Check Your Fermentation';
      default:
        return '🌱 Fermentation Reminder';
    }
  }

  /// Get follow-up notification message based on escalation level
  String _getFollowUpMessage(String stageLabel, int level, String title) {
    switch (level) {
      case 0:
        return '$title\n\nJust a friendly reminder about your $stageLabel stage.';
      case 1:
        return '$title\n\nYour $stageLabel stage is waiting for you.';
      case 2:
        return '$title\n\nYour $stageLabel stage is overdue. Please check your fermentation.';
      case 3:
        return '$title\n\nURGENT: Your $stageLabel stage is significantly overdue. This may affect your fermentation quality.';
      case 4:
        return '$title\n\nCRITICAL: Your $stageLabel stage has been overdue for days. Please check your fermentation immediately.';
      default:
        return '$title\n\nReminder about your $stageLabel stage.';
    }
  }

  /// Schedule completion notification
  Future<void> scheduleCompletionNotification(String logId, String title) async {
    try {
      await _localNotifications.show(
        logId.hashCode + 999, // Unique ID for completion notification
        'Fermentation Complete!',
        '$title has finished fermenting',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fermentation_channel',
            'Fermentation Notifications',
            channelDescription: 'Notifications for fermentation stages',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'fermentation_complete:$logId',
      );
    } catch (e) {
      AppLogger.error('Failed to schedule completion notification: $e', e);
    }
  }

  /// Cancel fermentation notifications
  Future<void> cancelFermentationNotifications(String logId) async {
    try {
      // Cancel all notifications for this fermentation log
      // We'll cancel a range of IDs that could be used for this log
      for (int i = 0; i < 100; i++) {
        await _localNotifications.cancel(logId.hashCode + i);
      }
      // Also cancel the completion notification
      await _localNotifications.cancel(logId.hashCode + 999);
    } catch (e) {
      AppLogger.error('Failed to cancel fermentation notifications: $e', e);
    }
  }

  /// Show simple notification
  Future<void> showSimple(String title, String body) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general_channel',
            'General Notifications',
            channelDescription: 'General app notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to show simple notification: $e', e);
    }
  }


  /// Send announcement notification to all users
  Future<void> sendAnnouncementNotification({
    required String title,
    required String body,
    required String announcementId,
  }) async {
    try {
      await _ensureInitialized();
      
      // Get current user to skip them
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;
      
      // Get all users except admins and current user
      final usersSnap = await _db.collection('users').get();
      
      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data();
        final role = (data['role'] as String?)?.toLowerCase();
        final userId = userDoc.id;
        
        // Skip admins and current user - they don't need to receive their own announcements
        if (role == 'admin' || userId == currentUserId) continue;
        
        // Always create database record (this will be delivered when user logs in)
        await _createNotificationRecord(
          userId: userId,
          title: '📢 $title',
          body: body,
          type: 'announcement',
          data: {
            'announcementId': announcementId,
            'action': 'announcement',
            'pendingLocalNotification': true, // Flag to send local notification on login
          },
        );
        
        // Try to send local notification if user is currently logged in
        try {
          await _localNotifications.show(
            announcementId.hashCode + userId.hashCode,
            '📢 $title',
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'announcements_channel',
                'Announcements',
                channelDescription: 'Important announcements from administrators',
                importance: Importance.max,
                priority: Priority.max,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
                enableLights: true,
                ledColor: const Color(0xFF2196F3),
                ledOnMs: 1000,
                ledOffMs: 500,
                showWhen: true,
                playSound: true,
                category: AndroidNotificationCategory.message,
                actions: const [
                  AndroidNotificationAction(
                    'view_announcement',
                    'View Details',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'mark_read',
                    'Mark as Read',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
                categoryIdentifier: 'ANNOUNCEMENT',
                threadIdentifier: 'announcement_$announcementId',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            payload: 'announcement:$announcementId',
          );
          
          AppLogger.info('Announcement notification delivered to logged-in user $userId');
        } catch (e) {
          // User is not logged in - notification will be delivered when they log in
          AppLogger.info('User $userId is not logged in - notification queued for delivery on login');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to send announcement notification: $e', e);
    }
  }

  /// Send report notification to admins
  Future<void> sendReportNotification({
    required String reportId,
    required String reportType,
    required String reportedContent,
    required String reporterName,
    required String reason,
  }) async {
    try {
      await _ensureInitialized();
      
      // Get all admin users
      final adminQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        final adminId = adminDoc.id;
        
        // Always create database record (this will be delivered when admin logs in)
        await _createNotificationRecord(
          userId: adminId,
          title: '🚨 New Report',
          body: '$reporterName reported $reportType: $reportedContent\nReason: $reason',
          type: 'report',
          data: {
            'reportId': reportId,
            'reportType': reportType,
            'reportedContent': reportedContent,
            'reporterName': reporterName,
            'reason': reason,
            'action': 'report',
            'pendingLocalNotification': true, // Flag to send local notification on login
          },
        );
        
        // Try to send local notification if admin is currently logged in
        try {
          await _localNotifications.show(
            reportId.hashCode + adminId.hashCode,
            '🚨 New Report',
            '$reporterName reported $reportType: $reportedContent\nReason: $reason',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'reports_channel',
                'Reports',
                channelDescription: 'Community reports requiring attention',
                importance: Importance.max,
                priority: Priority.max,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 300, 100, 300, 100, 300]),
                enableLights: true,
                ledColor: const Color(0xFFFF5722),
                ledOnMs: 1000,
                ledOffMs: 500,
                showWhen: true,
                playSound: true,
                category: AndroidNotificationCategory.status,
                actions: const [
                  AndroidNotificationAction(
                    'view_report',
                    'Review Report',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'dismiss',
                    'Dismiss',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
                categoryIdentifier: 'REPORT',
                threadIdentifier: 'report_$reportId',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            payload: 'report:$reportId',
          );
          
          AppLogger.info('Report notification delivered to logged-in admin $adminId');
        } catch (e) {
          // Admin is not logged in - notification will be delivered when they log in
          AppLogger.info('Admin $adminId is not logged in - notification queued for delivery on login');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to send report notification: $e', e);
    }
  }


  /// Deliver pending notifications when user logs in
  Future<void> deliverPendingNotifications(String userId) async {
    try {
      await _ensureInitialized();
      
      // Get all pending notifications for this user
      final pendingQuery = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('data.pendingLocalNotification', isEqualTo: true)
          .get();

      for (final doc in pendingQuery.docs) {
        final data = doc.data();
        final title = data['title'] as String;
        final body = data['body'] as String;
        final type = data['type'] as String;
        final notificationData = data['data'] as Map<String, dynamic>? ?? {};

        // Send local notification
        try {
          await _localNotifications.show(
            doc.id.hashCode,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                type == 'announcement' ? 'announcements_channel' : 'reports_channel',
                type == 'announcement' ? 'Announcements' : 'Reports',
                channelDescription: type == 'announcement' 
                    ? 'Important announcements from administrators'
                    : 'Community reports requiring attention',
                importance: Importance.max,
                priority: Priority.max,
                enableVibration: true,
                vibrationPattern: Int64List.fromList(
                  type == 'announcement' 
                      ? [0, 500, 200, 500]
                      : [0, 300, 100, 300, 100, 300]
                ),
                enableLights: true,
                ledColor: type == 'announcement' 
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFFF5722),
                ledOnMs: 1000,
                ledOffMs: 500,
                showWhen: true,
                playSound: true,
                category: type == 'announcement' 
                    ? AndroidNotificationCategory.message
                    : AndroidNotificationCategory.status,
                actions: type == 'announcement' 
                    ? const [
                        AndroidNotificationAction(
                          'view_announcement',
                          'View Details',
                          showsUserInterface: true,
                        ),
                        AndroidNotificationAction(
                          'mark_read',
                          'Mark as Read',
                          showsUserInterface: false,
                        ),
                      ]
                    : const [
                        AndroidNotificationAction(
                          'view_report',
                          'Review Report',
                          showsUserInterface: true,
                        ),
                        AndroidNotificationAction(
                          'dismiss',
                          'Dismiss',
                          showsUserInterface: false,
                        ),
                      ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
                categoryIdentifier: type == 'announcement' ? 'ANNOUNCEMENT' : 'REPORT',
                threadIdentifier: '${type}_${notificationData['announcementId'] ?? notificationData['reportId'] ?? ''}',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            payload: '$type:${notificationData['announcementId'] ?? notificationData['reportId'] ?? ''}',
          );

          // Mark as delivered (user is authenticated as themselves, so they have permission)
          await doc.reference.update({
            'data.pendingLocalNotification': false,
            'deliveredAt': FieldValue.serverTimestamp(),
          });

          AppLogger.info('Delivered pending notification to user $userId: $title');
        } catch (e) {
          AppLogger.error('Failed to deliver pending notification: $e', e);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to deliver pending notifications: $e', e);
    }
  }

  /// Convert DateTime to TZDateTime for scheduling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}