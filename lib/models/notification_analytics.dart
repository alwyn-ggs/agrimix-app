import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing notification analytics and engagement metrics
class NotificationAnalytics {
  final String userId;
  final int totalNotificationsSent;
  final int totalNotificationsDelivered;
  final int totalNotificationsOpened;
  final int totalNotificationsClicked;
  final int totalNotificationsDismissed;
  final double openRate; // Percentage of delivered notifications that were opened
  final double clickRate; // Percentage of opened notifications that were clicked
  final double dismissRate; // Percentage of delivered notifications that were dismissed
  final Map<String, int> notificationsByType;
  final Map<String, double> engagementByType;
  final Map<String, int> notificationsByHour;
  final Map<String, int> notificationsByDay;
  final DateTime lastNotificationSent;
  final DateTime lastNotificationOpened;
  final int averageTimeToOpen; // Minutes
  final int averageTimeToClick; // Minutes
  final List<NotificationEngagementEvent> recentEvents;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationAnalytics({
    required this.userId,
    required this.totalNotificationsSent,
    required this.totalNotificationsDelivered,
    required this.totalNotificationsOpened,
    required this.totalNotificationsClicked,
    required this.totalNotificationsDismissed,
    required this.openRate,
    required this.clickRate,
    required this.dismissRate,
    required this.notificationsByType,
    required this.engagementByType,
    required this.notificationsByHour,
    required this.notificationsByDay,
    required this.lastNotificationSent,
    required this.lastNotificationOpened,
    required this.averageTimeToOpen,
    required this.averageTimeToClick,
    required this.recentEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory NotificationAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationAnalytics(
      userId: doc.id,
      totalNotificationsSent: data['totalNotificationsSent'] ?? 0,
      totalNotificationsDelivered: data['totalNotificationsDelivered'] ?? 0,
      totalNotificationsOpened: data['totalNotificationsOpened'] ?? 0,
      totalNotificationsClicked: data['totalNotificationsClicked'] ?? 0,
      totalNotificationsDismissed: data['totalNotificationsDismissed'] ?? 0,
      openRate: (data['openRate'] ?? 0.0).toDouble(),
      clickRate: (data['clickRate'] ?? 0.0).toDouble(),
      dismissRate: (data['dismissRate'] ?? 0.0).toDouble(),
      notificationsByType: Map<String, int>.from(data['notificationsByType'] ?? {}),
      engagementByType: Map<String, double>.from(data['engagementByType'] ?? {}),
      notificationsByHour: Map<String, int>.from(data['notificationsByHour'] ?? {}),
      notificationsByDay: Map<String, int>.from(data['notificationsByDay'] ?? {}),
      lastNotificationSent: data['lastNotificationSent'] != null 
          ? (data['lastNotificationSent'] as Timestamp).toDate()
          : DateTime.now(),
      lastNotificationOpened: data['lastNotificationOpened'] != null 
          ? (data['lastNotificationOpened'] as Timestamp).toDate()
          : DateTime.now(),
      averageTimeToOpen: data['averageTimeToOpen'] ?? 0,
      averageTimeToClick: data['averageTimeToClick'] ?? 0,
      recentEvents: (data['recentEvents'] as List<dynamic>? ?? [])
          .map((e) => NotificationEngagementEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'totalNotificationsSent': totalNotificationsSent,
      'totalNotificationsDelivered': totalNotificationsDelivered,
      'totalNotificationsOpened': totalNotificationsOpened,
      'totalNotificationsClicked': totalNotificationsClicked,
      'totalNotificationsDismissed': totalNotificationsDismissed,
      'openRate': openRate,
      'clickRate': clickRate,
      'dismissRate': dismissRate,
      'notificationsByType': notificationsByType,
      'engagementByType': engagementByType,
      'notificationsByHour': notificationsByHour,
      'notificationsByDay': notificationsByDay,
      'lastNotificationSent': Timestamp.fromDate(lastNotificationSent),
      'lastNotificationOpened': Timestamp.fromDate(lastNotificationOpened),
      'averageTimeToOpen': averageTimeToOpen,
      'averageTimeToClick': averageTimeToClick,
      'recentEvents': recentEvents.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  NotificationAnalytics copyWith({
    String? userId,
    int? totalNotificationsSent,
    int? totalNotificationsDelivered,
    int? totalNotificationsOpened,
    int? totalNotificationsClicked,
    int? totalNotificationsDismissed,
    double? openRate,
    double? clickRate,
    double? dismissRate,
    Map<String, int>? notificationsByType,
    Map<String, double>? engagementByType,
    Map<String, int>? notificationsByHour,
    Map<String, int>? notificationsByDay,
    DateTime? lastNotificationSent,
    DateTime? lastNotificationOpened,
    int? averageTimeToOpen,
    int? averageTimeToClick,
    List<NotificationEngagementEvent>? recentEvents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationAnalytics(
      userId: userId ?? this.userId,
      totalNotificationsSent: totalNotificationsSent ?? this.totalNotificationsSent,
      totalNotificationsDelivered: totalNotificationsDelivered ?? this.totalNotificationsDelivered,
      totalNotificationsOpened: totalNotificationsOpened ?? this.totalNotificationsOpened,
      totalNotificationsClicked: totalNotificationsClicked ?? this.totalNotificationsClicked,
      totalNotificationsDismissed: totalNotificationsDismissed ?? this.totalNotificationsDismissed,
      openRate: openRate ?? this.openRate,
      clickRate: clickRate ?? this.clickRate,
      dismissRate: dismissRate ?? this.dismissRate,
      notificationsByType: notificationsByType ?? this.notificationsByType,
      engagementByType: engagementByType ?? this.engagementByType,
      notificationsByHour: notificationsByHour ?? this.notificationsByHour,
      notificationsByDay: notificationsByDay ?? this.notificationsByDay,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
      lastNotificationOpened: lastNotificationOpened ?? this.lastNotificationOpened,
      averageTimeToOpen: averageTimeToOpen ?? this.averageTimeToOpen,
      averageTimeToClick: averageTimeToClick ?? this.averageTimeToClick,
      recentEvents: recentEvents ?? this.recentEvents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get default analytics for a new user
  static NotificationAnalytics getDefault(String userId) {
    final now = DateTime.now();
    return NotificationAnalytics(
      userId: userId,
      totalNotificationsSent: 0,
      totalNotificationsDelivered: 0,
      totalNotificationsOpened: 0,
      totalNotificationsClicked: 0,
      totalNotificationsDismissed: 0,
      openRate: 0.0,
      clickRate: 0.0,
      dismissRate: 0.0,
      notificationsByType: {},
      engagementByType: {},
      notificationsByHour: {},
      notificationsByDay: {},
      lastNotificationSent: now,
      lastNotificationOpened: now,
      averageTimeToOpen: 0,
      averageTimeToClick: 0,
      recentEvents: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Individual notification engagement event
class NotificationEngagementEvent {
  final String notificationId;
  final String type; // 'sent', 'delivered', 'opened', 'clicked', 'dismissed'
  final String notificationType; // 'announcement', 'fermentation_reminder', etc.
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const NotificationEngagementEvent({
    required this.notificationId,
    required this.type,
    required this.notificationType,
    required this.timestamp,
    required this.metadata,
  });

  factory NotificationEngagementEvent.fromMap(Map<String, dynamic> map) {
    return NotificationEngagementEvent(
      notificationId: map['notificationId'] ?? '',
      type: map['type'] ?? '',
      notificationType: map['notificationType'] ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'type': type,
      'notificationType': notificationType,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Notification performance summary for a specific time period
class NotificationPerformanceSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final int totalDismissed;
  final double openRate;
  final double clickRate;
  final double dismissRate;
  final Map<String, int> topNotificationTypes;
  final Map<String, int> hourlyDistribution;
  final Map<String, int> dailyDistribution;
  final List<NotificationEngagementEvent> topPerformingNotifications;
  final String timezone;

  const NotificationPerformanceSummary({
    required this.startDate,
    required this.endDate,
    required this.totalSent,
    required this.totalDelivered,
    required this.totalOpened,
    required this.totalClicked,
    required this.totalDismissed,
    required this.openRate,
    required this.clickRate,
    required this.dismissRate,
    required this.topNotificationTypes,
    required this.hourlyDistribution,
    required this.dailyDistribution,
    required this.topPerformingNotifications,
    required this.timezone,
  });

  /// Calculate engagement score (0-100)
  double get engagementScore {
    if (totalDelivered == 0) return 0.0;
    return ((openRate * 0.4) + (clickRate * 0.6)) * 100;
  }

  /// Get performance rating
  String get performanceRating {
    final score = engagementScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Very Poor';
  }
}
