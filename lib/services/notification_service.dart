import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Handle notification actions (when user taps on notification buttons)
  static void handleNotificationAction(String action, String payload) {
    switch (action) {
      case 'open_app':
        // Navigate to fermentation detail page
        // This would typically be handled by your app's navigation system
        AppLogger.info('User tapped "Open App" for payload: $payload');
        break;
      case 'mark_done':
        // Mark fermentation stage as completed
        AppLogger.info('User tapped "Mark as Done" for payload: $payload');
        // You can implement logic to update the fermentation log here
        break;
      default:
        AppLogger.info('Unknown notification action: $action');
    }
  }

  /// Test notification (for development/testing)
  Future<void> testFermentationNotification() async {
    try {
      await _localNotifications.show(
        999, // Test ID
        '🌱 Test Fermentation Alert!',
        'This is a test notification to check if fermentation alerts work properly.\n\nDay 3: Stir mixture and check aroma\n\nTap to open the app and track your progress.',
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
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            categoryIdentifier: 'FERMENTATION_REMINDER',
            threadIdentifier: 'test_fermentation',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: 'test:fermentation:999',
      );
    } catch (e) {
      AppLogger.error('Failed to show test notification: $e', e);
    }
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
      final usersSnap = await _db.collection('users').get();
      final batch = _db.batch();
      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data();
        final role = (data['role'] as String?)?.toLowerCase();
        // Skip admins: Admins should not receive admin announcements in their bell
        if (role == 'admin') {
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

  /// Schedule fermentation notifications
  Future<void> scheduleFermentationNotifications(
    String logId,
    String title,
    List<Map<String, dynamic>> stages,
    DateTime startDate,
  ) async {
    try {
      // Schedule notifications for each stage
      for (int i = 0; i < stages.length; i++) {
        final stage = stages[i];
        final day = stage['day'] as int;
        final stageLabel = stage['label'] as String? ?? 'Stage ${i + 1}';
        final stageAction = stage['action'] as String? ?? '';
        final notificationDate = startDate.add(Duration(days: day));
        
        // Only schedule if the date is in the future
        if (notificationDate.isAfter(DateTime.now())) {
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
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'fermentation:$logId:$i',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to schedule fermentation notifications: $e', e);
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


  /// Convert DateTime to TZDateTime for scheduling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}