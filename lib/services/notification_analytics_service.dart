import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_analytics.dart';
import '../utils/logger.dart';

/// Service for tracking and analyzing notification performance and engagement
class NotificationAnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Track notification sent event
  Future<void> trackNotificationSent({
    required String userId,
    required String notificationId,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recordEngagementEvent(
        userId: userId,
        notificationId: notificationId,
        type: 'sent',
        notificationType: notificationType,
        metadata: metadata ?? {},
      );

      await _updateAnalyticsCounters(userId, {
        'totalNotificationsSent': FieldValue.increment(1),
        'lastNotificationSent': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Tracked notification sent: $notificationId for user $userId');
    } catch (e) {
      AppLogger.error('Failed to track notification sent: $e', e);
    }
  }

  /// Track notification delivered event
  Future<void> trackNotificationDelivered({
    required String userId,
    required String notificationId,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recordEngagementEvent(
        userId: userId,
        notificationId: notificationId,
        type: 'delivered',
        notificationType: notificationType,
        metadata: metadata ?? {},
      );

      await _updateAnalyticsCounters(userId, {
        'totalNotificationsDelivered': FieldValue.increment(1),
      });

      AppLogger.info('Tracked notification delivered: $notificationId for user $userId');
    } catch (e) {
      AppLogger.error('Failed to track notification delivered: $e', e);
    }
  }

  /// Track notification opened event
  Future<void> trackNotificationOpened({
    required String userId,
    required String notificationId,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      
      await _recordEngagementEvent(
        userId: userId,
        notificationId: notificationId,
        type: 'opened',
        notificationType: notificationType,
        metadata: metadata ?? {},
      );

      await _updateAnalyticsCounters(userId, {
        'totalNotificationsOpened': FieldValue.increment(1),
        'lastNotificationOpened': FieldValue.serverTimestamp(),
      });

      // Update type-specific counters
      await _updateTypeCounters(userId, notificationType, 'opened');

      // Calculate and update rates
      await _updateEngagementRates(userId);

      AppLogger.info('Tracked notification opened: $notificationId for user $userId');
    } catch (e) {
      AppLogger.error('Failed to track notification opened: $e', e);
    }
  }

  /// Track notification clicked event
  Future<void> trackNotificationClicked({
    required String userId,
    required String notificationId,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recordEngagementEvent(
        userId: userId,
        notificationId: notificationId,
        type: 'clicked',
        notificationType: notificationType,
        metadata: metadata ?? {},
      );

      await _updateAnalyticsCounters(userId, {
        'totalNotificationsClicked': FieldValue.increment(1),
      });

      // Update type-specific counters
      await _updateTypeCounters(userId, notificationType, 'clicked');

      // Calculate and update rates
      await _updateEngagementRates(userId);

      AppLogger.info('Tracked notification clicked: $notificationId for user $userId');
    } catch (e) {
      AppLogger.error('Failed to track notification clicked: $e', e);
    }
  }

  /// Track notification dismissed event
  Future<void> trackNotificationDismissed({
    required String userId,
    required String notificationId,
    required String notificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recordEngagementEvent(
        userId: userId,
        notificationId: notificationId,
        type: 'dismissed',
        notificationType: notificationType,
        metadata: metadata ?? {},
      );

      await _updateAnalyticsCounters(userId, {
        'totalNotificationsDismissed': FieldValue.increment(1),
      });

      // Update type-specific counters
      await _updateTypeCounters(userId, notificationType, 'dismissed');

      // Calculate and update rates
      await _updateEngagementRates(userId);

      AppLogger.info('Tracked notification dismissed: $notificationId for user $userId');
    } catch (e) {
      AppLogger.error('Failed to track notification dismissed: $e', e);
    }
  }

  /// Get user notification analytics
  Future<NotificationAnalytics?> getUserAnalytics(String userId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        // Create default analytics if they don't exist
        final defaultAnalytics = NotificationAnalytics.getDefault(userId);
        await _saveAnalytics(defaultAnalytics);
        return defaultAnalytics;
      }

      return NotificationAnalytics.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get notification analytics: $e', e);
      return null;
    }
  }

  /// Get notification performance summary for a time period
  Future<NotificationPerformanceSummary?> getPerformanceSummary(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
    String timezone = 'UTC',
  }) async {
    try {
      // Get engagement events for the time period
      final eventsQuery = await _db
          .collection('users')
          .doc(userId)
          .collection('engagement_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      final events = eventsQuery.docs
          .map((doc) => NotificationEngagementEvent.fromMap(doc.data()))
          .toList();

      // Calculate metrics
      final sentEvents = events.where((e) => e.type == 'sent').toList();
      final deliveredEvents = events.where((e) => e.type == 'delivered').toList();
      final openedEvents = events.where((e) => e.type == 'opened').toList();
      final clickedEvents = events.where((e) => e.type == 'clicked').toList();
      final dismissedEvents = events.where((e) => e.type == 'dismissed').toList();

      final totalSent = sentEvents.length;
      final totalDelivered = deliveredEvents.length;
      final totalOpened = openedEvents.length;
      final totalClicked = clickedEvents.length;
      final totalDismissed = dismissedEvents.length;

      final openRate = totalDelivered > 0 ? (totalOpened / totalDelivered) : 0.0;
      final clickRate = totalOpened > 0 ? (totalClicked / totalOpened) : 0.0;
      final dismissRate = totalDelivered > 0 ? (totalDismissed / totalDelivered) : 0.0;

      // Group by type
      final notificationsByType = <String, int>{};
      for (final event in sentEvents) {
        notificationsByType[event.notificationType] = 
            (notificationsByType[event.notificationType] ?? 0) + 1;
      }

      // Group by hour
      final notificationsByHour = <String, int>{};
      for (final event in sentEvents) {
        final hour = event.timestamp.hour.toString().padLeft(2, '0');
        notificationsByHour[hour] = (notificationsByHour[hour] ?? 0) + 1;
      }

      // Group by day
      final notificationsByDay = <String, int>{};
      for (final event in sentEvents) {
        final day = _getDayName(event.timestamp.weekday);
        notificationsByDay[day] = (notificationsByDay[day] ?? 0) + 1;
      }

      // Get top performing notifications (by engagement)
      final topPerformingNotifications = _getTopPerformingNotifications(events);

      return NotificationPerformanceSummary(
        startDate: startDate,
        endDate: endDate,
        totalSent: totalSent,
        totalDelivered: totalDelivered,
        totalOpened: totalOpened,
        totalClicked: totalClicked,
        totalDismissed: totalDismissed,
        openRate: openRate,
        clickRate: clickRate,
        dismissRate: dismissRate,
        topNotificationTypes: notificationsByType,
        hourlyDistribution: notificationsByHour,
        dailyDistribution: notificationsByDay,
        topPerformingNotifications: topPerformingNotifications,
        timezone: timezone,
      );
    } catch (e) {
      AppLogger.error('Failed to get performance summary: $e', e);
      return null;
    }
  }

  /// Get engagement trends over time
  Future<List<Map<String, dynamic>>> getEngagementTrends(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily', // 'hourly', 'daily', 'weekly'
  }) async {
    try {
      final eventsQuery = await _db
          .collection('users')
          .doc(userId)
          .collection('engagement_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      final events = eventsQuery.docs
          .map((doc) => NotificationEngagementEvent.fromMap(doc.data()))
          .toList();

      // Group events by time period
      final Map<String, Map<String, int>> groupedEvents = {};
      
      for (final event in events) {
        String timeKey;
        switch (granularity) {
          case 'hourly':
            timeKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')} ${event.timestamp.hour.toString().padLeft(2, '0')}:00';
            break;
          case 'weekly':
            final weekStart = event.timestamp.subtract(Duration(days: event.timestamp.weekday - 1));
            timeKey = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
            break;
          default: // daily
            timeKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}';
        }

        if (!groupedEvents.containsKey(timeKey)) {
          groupedEvents[timeKey] = {
            'sent': 0,
            'delivered': 0,
            'opened': 0,
            'clicked': 0,
            'dismissed': 0,
          };
        }

        groupedEvents[timeKey]![event.type] = 
            (groupedEvents[timeKey]![event.type] ?? 0) + 1;
      }

      // Convert to list format
      return groupedEvents.entries.map((entry) {
        final data = entry.value;
        final openRate = data['delivered']! > 0 ? (data['opened']! / data['delivered']!) : 0.0;
        final clickRate = data['opened']! > 0 ? (data['clicked']! / data['opened']!) : 0.0;
        
        return {
          'date': entry.key,
          'sent': data['sent']!,
          'delivered': data['delivered']!,
          'opened': data['opened']!,
          'clicked': data['clicked']!,
          'dismissed': data['dismissed']!,
          'openRate': openRate,
          'clickRate': clickRate,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get engagement trends: $e', e);
      return [];
    }
  }

  /// Record engagement event
  Future<void> _recordEngagementEvent({
    required String userId,
    required String notificationId,
    required String type,
    required String notificationType,
    required Map<String, dynamic> metadata,
  }) async {
    final event = NotificationEngagementEvent(
      notificationId: notificationId,
      type: type,
      notificationType: notificationType,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('engagement_events')
        .add(event.toMap());
  }

  /// Update analytics counters
  Future<void> _updateAnalyticsCounters(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('analytics')
        .doc('notifications')
        .set(updates, SetOptions(merge: true));
  }

  /// Update type-specific counters
  Future<void> _updateTypeCounters(
    String userId,
    String notificationType,
    String action,
  ) async {
    final fieldName = 'notificationsByType.$notificationType';
    await _db
        .collection('users')
        .doc(userId)
        .collection('analytics')
        .doc('notifications')
        .update({
      fieldName: FieldValue.increment(1),
    });
  }

  /// Update engagement rates
  Future<void> _updateEngagementRates(String userId) async {
    try {
      final analytics = await getUserAnalytics(userId);
      if (analytics == null) return;

      final openRate = analytics.totalNotificationsDelivered > 0 
          ? analytics.totalNotificationsOpened / analytics.totalNotificationsDelivered 
          : 0.0;
      
      final clickRate = analytics.totalNotificationsOpened > 0 
          ? analytics.totalNotificationsClicked / analytics.totalNotificationsOpened 
          : 0.0;
      
      final dismissRate = analytics.totalNotificationsDelivered > 0 
          ? analytics.totalNotificationsDismissed / analytics.totalNotificationsDelivered 
          : 0.0;

      await _updateAnalyticsCounters(userId, {
        'openRate': openRate,
        'clickRate': clickRate,
        'dismissRate': dismissRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to update engagement rates: $e', e);
    }
  }

  /// Save analytics to Firestore
  Future<void> _saveAnalytics(NotificationAnalytics analytics) async {
    await _db
        .collection('users')
        .doc(analytics.userId)
        .collection('analytics')
        .doc('notifications')
        .set(analytics.toFirestore());
  }

  /// Get top performing notifications
  List<NotificationEngagementEvent> _getTopPerformingNotifications(
    List<NotificationEngagementEvent> events,
  ) {
    final Map<String, List<NotificationEngagementEvent>> groupedByNotification = {};
    
    for (final event in events) {
      if (!groupedByNotification.containsKey(event.notificationId)) {
        groupedByNotification[event.notificationId] = [];
      }
      groupedByNotification[event.notificationId]!.add(event);
    }

    // Calculate engagement score for each notification
    final List<MapEntry<String, double>> scoredNotifications = [];
    
    for (final entry in groupedByNotification.entries) {
      final notificationEvents = entry.value;
      final hasOpened = notificationEvents.any((e) => e.type == 'opened');
      final hasClicked = notificationEvents.any((e) => e.type == 'clicked');
      final hasDismissed = notificationEvents.any((e) => e.type == 'dismissed');
      
      double score = 0.0;
      if (hasOpened) score += 1.0;
      if (hasClicked) score += 2.0;
      if (hasDismissed) score -= 0.5;
      
      scoredNotifications.add(MapEntry(entry.key, score));
    }

    // Sort by score and return top 10
    scoredNotifications.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredNotifications
        .take(10)
        .map((entry) => groupedByNotification[entry.key]!.first)
        .toList();
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
