import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'messaging_service.dart';
import 'notification_preferences_service.dart';
import 'notification_analytics_service.dart';
import '../utils/logger.dart';

/// Enhanced notification service with customization, scheduling, and analytics
class EnhancedNotificationService {
  final MessagingService _messagingService;
  final NotificationPreferencesService _preferencesService;
  final NotificationAnalyticsService _analyticsService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  EnhancedNotificationService(
    this._messagingService,
    this._preferencesService,
    this._analyticsService,
  );

  bool _isInitialized = false;

  /// Initialize the enhanced notification service
  Future<void> init() async {
    if (_isInitialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    _isInitialized = true;
  }

  /// Send personalized notification with user preferences
  Future<void> sendPersonalizedNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    DateTime? scheduledTime,
    bool respectPreferences = true,
  }) async {
    try {
      await _ensureInitialized();

      // Check user preferences if enabled
      if (respectPreferences) {
        final shouldSend = await _preferencesService.shouldSendNotification(
          userId,
          type,
          scheduledTime: scheduledTime,
        );
        
        if (!shouldSend) {
          AppLogger.info('Notification blocked by user preferences: $type for user $userId');
          return;
        }
      }

      // Track notification sent
      await _analyticsService.trackNotificationSent(
        userId: userId,
        notificationId: '${DateTime.now().millisecondsSinceEpoch}_$type',
        notificationType: type,
        metadata: data,
      );

      // Send via FCM
      await _sendFCMNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      // Send local notification if user is active
      await _sendLocalNotification(
        title: title,
        body: body,
        type: type,
        data: data,
      );

      AppLogger.info('Personalized notification sent: $type to user $userId');
    } catch (e) {
      AppLogger.error('Failed to send personalized notification: $e', e);
    }
  }

  /// Send scheduled notification at optimal time
  Future<void> sendScheduledNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    DateTime? preferredTime,
  }) async {
    try {
      await _ensureInitialized();

      // Get optimal send time based on user preferences
      DateTime? sendTime = preferredTime ?? await _preferencesService.getOptimalSendTime(userId);

      if (sendTime == null) {
        // Send immediately if no optimal time found
        await sendPersonalizedNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        return;
      }

      // Schedule the notification
      await _scheduleNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        scheduledTime: sendTime,
      );

      AppLogger.info('Scheduled notification: $type for user $userId at $sendTime');
    } catch (e) {
      AppLogger.error('Failed to send scheduled notification: $e', e);
    }
  }

  /// Send batch notifications with frequency limits
  Future<void> sendBatchNotifications({
    required String userId,
    required List<NotificationBatchItem> notifications,
    bool respectFrequencyLimits = true,
  }) async {
    try {
      await _ensureInitialized();

      if (respectFrequencyLimits) {
        final limits = await _preferencesService.getFrequencyLimits(userId);
        final dailyLimit = limits['daily'] ?? 10;
        final weeklyLimit = limits['weekly'] ?? 50;

        // Check daily limit
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final dailyCount = await _getNotificationCount(userId, startOfDay, today);
        
        if (dailyCount >= dailyLimit) {
          AppLogger.info('Daily notification limit reached for user $userId');
          return;
        }

        // Check weekly limit
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final weeklyCount = await _getNotificationCount(userId, startOfWeek, today);
        
        if (weeklyCount >= weeklyLimit) {
          AppLogger.info('Weekly notification limit reached for user $userId');
          return;
        }

        // Limit notifications to remaining daily allowance
        final remainingDaily = dailyLimit - dailyCount;
        notifications = notifications.take(remainingDaily).toList();
      }

      // Send notifications
      for (final notification in notifications) {
        await sendPersonalizedNotification(
          userId: userId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          data: notification.data,
        );
      }

      AppLogger.info('Batch notifications sent: ${notifications.length} to user $userId');
    } catch (e) {
      AppLogger.error('Failed to send batch notifications: $e', e);
    }
  }

  /// Send digest notification
  Future<void> sendDigestNotification({
    required String userId,
    required List<DigestItem> items,
  }) async {
    try {
      await _ensureInitialized();

      final prefs = await _preferencesService.getUserPreferences(userId);
      if (prefs == null || !prefs.digestEnabled) return;

      final title = _getDigestTitle(prefs.digestFrequency);
      final body = _buildDigestBody(items);

      await sendPersonalizedNotification(
        userId: userId,
        title: title,
        body: body,
        type: 'digest',
        data: {
          'items': items.map((item) => item.toMap()).toList(),
          'frequency': prefs.digestFrequency,
        },
      );

      AppLogger.info('Digest notification sent to user $userId');
    } catch (e) {
      AppLogger.error('Failed to send digest notification: $e', e);
    }
  }

  /// Send notification with enhanced actions
  Future<void> sendInteractiveNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required List<NotificationAction> actions,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _ensureInitialized();

      // Track notification sent
      await _analyticsService.trackNotificationSent(
        userId: userId,
        notificationId: '${DateTime.now().millisecondsSinceEpoch}_$type',
        notificationType: type,
        metadata: data,
      );

      // Send FCM with actions
      await _sendFCMNotificationWithActions(
        userId: userId,
        title: title,
        body: body,
        type: type,
        actions: actions,
        data: data,
      );

      // Send local notification with actions
      await _sendLocalNotificationWithActions(
        title: title,
        body: body,
        type: type,
        actions: actions,
        data: data,
      );

      AppLogger.info('Interactive notification sent: $type to user $userId');
    } catch (e) {
      AppLogger.error('Failed to send interactive notification: $e', e);
    }
  }

  /// Handle notification action with analytics
  Future<void> handleNotificationAction({
    required String userId,
    required String notificationId,
    required String action,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Track action in analytics
      await _analyticsService.trackNotificationClicked(
        userId: userId,
        notificationId: notificationId,
        notificationType: notificationType,
        metadata: metadata,
      );

      // Handle the action
      switch (action) {
        case 'open_app':
          _navigateToApp();
          break;
        case 'mark_done':
          _handleMarkDone(notificationId, metadata);
          break;
        case 'view_details':
          _handleViewDetails(notificationId, metadata);
          break;
        case 'quick_reply':
          _handleQuickReply(notificationId, metadata);
          break;
        case 'snooze':
          _handleSnooze(notificationId, metadata);
          break;
        case 'dismiss':
          await _analyticsService.trackNotificationDismissed(
            userId: userId,
            notificationId: notificationId,
            notificationType: notificationType,
            metadata: metadata,
          );
          break;
        default:
          AppLogger.warning('Unknown notification action: $action');
      }
    } catch (e) {
      AppLogger.error('Failed to handle notification action: $e', e);
    }
  }

  /// Send FCM notification
  Future<void> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final tokens = await _messagingService.getUserTokens(userId);
      
      if (tokens.isNotEmpty) {
        // In a real implementation, you would send FCM messages here
        await _createNotificationRecord(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        
        // Track delivery
        await _analyticsService.trackNotificationDelivered(
          userId: userId,
          notificationId: '${DateTime.now().millisecondsSinceEpoch}_$type',
          notificationType: type,
          metadata: data,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send FCM notification: $e', e);
    }
  }

  /// Send FCM notification with actions
  Future<void> _sendFCMNotificationWithActions({
    required String userId,
    required String title,
    required String body,
    required String type,
    required List<NotificationAction> actions,
    Map<String, dynamic>? data,
  }) async {
    try {
      final tokens = await _messagingService.getUserTokens(userId);
      
      if (tokens.isNotEmpty) {
        await _createNotificationRecord(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: {
            ...?data,
            'actions': actions.map((a) => a.toMap()).toList(),
          },
        );
        
        // Track delivery
        await _analyticsService.trackNotificationDelivered(
          userId: userId,
          notificationId: '${DateTime.now().millisecondsSinceEpoch}_$type',
          notificationType: type,
          metadata: data,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send FCM notification with actions: $e', e);
    }
  }

  /// Send local notification
  Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'enhanced_notifications',
        'Enhanced Notifications',
        channelDescription: 'Personalized notifications with user preferences',
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
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: 'type:$type',
      );
    } catch (e) {
      AppLogger.error('Failed to send local notification: $e', e);
    }
  }

  /// Send local notification with actions
  Future<void> _sendLocalNotificationWithActions({
    required String title,
    required String body,
    required String type,
    required List<NotificationAction> actions,
    Map<String, dynamic>? data,
  }) async {
    try {
      final androidActions = actions.map((action) => AndroidNotificationAction(
        action.id,
        action.title,
        showsUserInterface: action.showsUserInterface,
      )).toList();

      final androidDetails = AndroidNotificationDetails(
        'enhanced_notifications',
        'Enhanced Notifications',
        channelDescription: 'Personalized notifications with user preferences',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        actions: androidActions,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: 'type:$type',
      );
    } catch (e) {
      AppLogger.error('Failed to send local notification with actions: $e', e);
    }
  }

  /// Schedule notification for later
  Future<void> _scheduleNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    required DateTime scheduledTime,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'scheduled_notifications',
        'Scheduled Notifications',
        channelDescription: 'Notifications scheduled based on user preferences',
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

      await _localNotifications.zonedSchedule(
        scheduledTime.millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        payload: 'type:$type',
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      AppLogger.error('Failed to schedule notification: $e', e);
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

  /// Get notification count for time period
  Future<int> _getNotificationCount(String userId, DateTime start, DateTime end) async {
    try {
      final query = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      
      return query.docs.length;
    } catch (e) {
      AppLogger.error('Failed to get notification count: $e', e);
      return 0;
    }
  }

  /// Get digest title based on frequency
  String _getDigestTitle(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily Digest';
      case 'weekly':
        return 'Weekly Digest';
      case 'monthly':
        return 'Monthly Digest';
      default:
        return 'Digest';
    }
  }

  /// Build digest body from items
  String _buildDigestBody(List<DigestItem> items) {
    if (items.isEmpty) return 'No new updates.';
    
    final buffer = StringBuffer();
    for (int i = 0; i < items.length && i < 5; i++) {
      final item = items[i];
      buffer.writeln('• ${item.title}');
    }
    
    if (items.length > 5) {
      buffer.writeln('• ... and ${items.length - 5} more');
    }
    
    return buffer.toString();
  }

  /// Navigation and action handlers
  void _navigateToApp() {
    // Implementation depends on your navigation setup
    AppLogger.info('Navigate to app');
  }

  void _handleMarkDone(String notificationId, Map<String, dynamic>? metadata) {
    // Implementation depends on your business logic
    AppLogger.info('Mark as done: $notificationId');
  }

  void _handleViewDetails(String notificationId, Map<String, dynamic>? metadata) {
    // Implementation depends on your navigation setup
    AppLogger.info('View details: $notificationId');
  }

  void _handleQuickReply(String notificationId, Map<String, dynamic>? metadata) {
    // Implementation depends on your business logic
    AppLogger.info('Quick reply: $notificationId');
  }

  void _handleSnooze(String notificationId, Map<String, dynamic>? metadata) {
    // Implementation depends on your business logic
    AppLogger.info('Snooze: $notificationId');
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
      _isInitialized = true;
    }
  }
}

/// Notification batch item for batch sending
class NotificationBatchItem {
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;

  const NotificationBatchItem({
    required this.title,
    required this.body,
    required this.type,
    this.data,
  });
}

/// Digest item for digest notifications
class DigestItem {
  final String title;
  final String description;
  final String type;
  final Map<String, dynamic>? data;

  const DigestItem({
    required this.title,
    required this.description,
    required this.type,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'data': data ?? {},
    };
  }
}

/// Notification action for interactive notifications
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;
  final Map<String, dynamic>? data;

  const NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = true,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'showsUserInterface': showsUserInterface,
      'data': data ?? {},
    };
  }
}
