import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing user notification preferences and settings
class NotificationPreferences {
  final String userId;
  final bool enabled;
  final NotificationTimePreferences timePreferences;
  final NotificationFrequencyPreferences frequencyPreferences;
  final Map<String, bool> notificationTypes;
  final Map<String, bool> channels;
  final bool quietHoursEnabled;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final List<String> quietDays; // Days of week when quiet hours apply
  final bool digestEnabled;
  final String digestFrequency; // 'daily', 'weekly', 'never'
  final String digestTime; // Time of day for digest
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.userId,
    required this.enabled,
    required this.timePreferences,
    required this.frequencyPreferences,
    required this.notificationTypes,
    required this.channels,
    required this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.quietDays,
    required this.digestEnabled,
    required this.digestFrequency,
    required this.digestTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    final Timestamp? createdTs = data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null;
    final Timestamp? updatedTs = data['updatedAt'] is Timestamp ? data['updatedAt'] as Timestamp : null;

    // Provide resilient defaults for maps and fields
    final Map<String, bool> types = {
      'announcements': true,
      'fermentation_reminders': true,
      'community_updates': true,
      'moderation_alerts': true,
      'system_updates': true,
      'marketing': false,
      ...Map<String, bool>.from(data['notificationTypes'] ?? {}),
    };

    final Map<String, bool> channels = {
      'push': true,
      'in_app': true,
      'email': false,
      'sms': false,
      ...Map<String, bool>.from(data['channels'] ?? {}),
    };

    return NotificationPreferences(
      userId: (data['userId'] as String?) ?? doc.reference.parent.parent?.id ?? '',
      enabled: (data['enabled'] as bool?) ?? true,
      timePreferences: NotificationTimePreferences.fromMap(
        (data['timePreferences'] as Map<String, dynamic>?) ?? {},
      ),
      frequencyPreferences: NotificationFrequencyPreferences.fromMap(
        (data['frequencyPreferences'] as Map<String, dynamic>?) ?? {},
      ),
      notificationTypes: types,
      channels: channels,
      quietHoursEnabled: (data['quietHoursEnabled'] as bool?) ?? false,
      quietHoursStart: data['quietHoursStart'] is Timestamp
          ? (data['quietHoursStart'] as Timestamp).toDate()
          : null,
      quietHoursEnd: data['quietHoursEnd'] is Timestamp
          ? (data['quietHoursEnd'] as Timestamp).toDate()
          : null,
      quietDays: List<String>.from((data['quietDays'] as List<dynamic>?) ?? const []),
      digestEnabled: (data['digestEnabled'] as bool?) ?? false,
      digestFrequency: (data['digestFrequency'] as String?) ?? 'daily',
      digestTime: (data['digestTime'] as String?) ?? '09:00',
      createdAt: createdTs?.toDate() ?? DateTime.now(),
      updatedAt: updatedTs?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'enabled': enabled,
      'timePreferences': timePreferences.toMap(),
      'frequencyPreferences': frequencyPreferences.toMap(),
      'notificationTypes': notificationTypes,
      'channels': channels,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart != null 
          ? Timestamp.fromDate(quietHoursStart!)
          : null,
      'quietHoursEnd': quietHoursEnd != null 
          ? Timestamp.fromDate(quietHoursEnd!)
          : null,
      'quietDays': quietDays,
      'digestEnabled': digestEnabled,
      'digestFrequency': digestFrequency,
      'digestTime': digestTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    String? userId,
    bool? enabled,
    NotificationTimePreferences? timePreferences,
    NotificationFrequencyPreferences? frequencyPreferences,
    Map<String, bool>? notificationTypes,
    Map<String, bool>? channels,
    bool? quietHoursEnabled,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    List<String>? quietDays,
    bool? digestEnabled,
    String? digestFrequency,
    String? digestTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      timePreferences: timePreferences ?? this.timePreferences,
      frequencyPreferences: frequencyPreferences ?? this.frequencyPreferences,
      notificationTypes: notificationTypes ?? this.notificationTypes,
      channels: channels ?? this.channels,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietDays: quietDays ?? this.quietDays,
      digestEnabled: digestEnabled ?? this.digestEnabled,
      digestFrequency: digestFrequency ?? this.digestFrequency,
      digestTime: digestTime ?? this.digestTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get default notification preferences
  static NotificationPreferences getDefault(String userId) {
    final now = DateTime.now();
    return NotificationPreferences(
      userId: userId,
      enabled: true,
      timePreferences: NotificationTimePreferences.getDefault(),
      frequencyPreferences: NotificationFrequencyPreferences.getDefault(),
      notificationTypes: {
        'announcements': true,
        'fermentation_reminders': true,
        'community_updates': true,
        'moderation_alerts': true,
        'system_updates': true,
        'marketing': false,
      },
      channels: {
        'push': true,
        'email': false,
        'sms': false,
        'in_app': true,
      },
      quietHoursEnabled: false,
      quietDays: [],
      digestEnabled: false,
      digestFrequency: 'daily',
      digestTime: '09:00',
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Time-based notification preferences
class NotificationTimePreferences {
  final String timezone;
  final List<int> preferredHours; // 0-23
  final List<String> preferredDays; // Monday, Tuesday, etc.
  final bool respectUserTimezone;
  final String timeFormat; // '12h' or '24h'

  const NotificationTimePreferences({
    required this.timezone,
    required this.preferredHours,
    required this.preferredDays,
    required this.respectUserTimezone,
    required this.timeFormat,
  });

  factory NotificationTimePreferences.fromMap(Map<String, dynamic> map) {
    return NotificationTimePreferences(
      timezone: map['timezone'] ?? 'UTC',
      preferredHours: List<int>.from(map['preferredHours'] ?? [9, 12, 18]),
      preferredDays: List<String>.from(map['preferredDays'] ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']),
      respectUserTimezone: map['respectUserTimezone'] ?? true,
      timeFormat: map['timeFormat'] ?? '12h',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timezone': timezone,
      'preferredHours': preferredHours,
      'preferredDays': preferredDays,
      'respectUserTimezone': respectUserTimezone,
      'timeFormat': timeFormat,
    };
  }

  static NotificationTimePreferences getDefault() {
    return const NotificationTimePreferences(
      timezone: 'UTC',
      preferredHours: [9, 12, 18],
      preferredDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      respectUserTimezone: true,
      timeFormat: '12h',
    );
  }

  /// Create a copy with updated fields
  NotificationTimePreferences copyWith({
    String? timezone,
    List<int>? preferredHours,
    List<String>? preferredDays,
    bool? respectUserTimezone,
    String? timeFormat,
  }) {
    return NotificationTimePreferences(
      timezone: timezone ?? this.timezone,
      preferredHours: preferredHours ?? this.preferredHours,
      preferredDays: preferredDays ?? this.preferredDays,
      respectUserTimezone: respectUserTimezone ?? this.respectUserTimezone,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}

/// Frequency-based notification preferences
class NotificationFrequencyPreferences {
  final String maxDailyNotifications;
  final String maxWeeklyNotifications;
  final bool batchSimilarNotifications;
  final int batchDelayMinutes;
  final bool respectUserActivity;
  final int cooldownMinutes; // Minimum time between notifications
  final bool adaptiveFrequency; // Adjust based on user engagement

  const NotificationFrequencyPreferences({
    required this.maxDailyNotifications,
    required this.maxWeeklyNotifications,
    required this.batchSimilarNotifications,
    required this.batchDelayMinutes,
    required this.respectUserActivity,
    required this.cooldownMinutes,
    required this.adaptiveFrequency,
  });

  factory NotificationFrequencyPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationFrequencyPreferences(
      maxDailyNotifications: map['maxDailyNotifications'] ?? '10',
      maxWeeklyNotifications: map['maxWeeklyNotifications'] ?? '50',
      batchSimilarNotifications: map['batchSimilarNotifications'] ?? true,
      batchDelayMinutes: map['batchDelayMinutes'] ?? 5,
      respectUserActivity: map['respectUserActivity'] ?? true,
      cooldownMinutes: map['cooldownMinutes'] ?? 30,
      adaptiveFrequency: map['adaptiveFrequency'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxDailyNotifications': maxDailyNotifications,
      'maxWeeklyNotifications': maxWeeklyNotifications,
      'batchSimilarNotifications': batchSimilarNotifications,
      'batchDelayMinutes': batchDelayMinutes,
      'respectUserActivity': respectUserActivity,
      'cooldownMinutes': cooldownMinutes,
      'adaptiveFrequency': adaptiveFrequency,
    };
  }

  static NotificationFrequencyPreferences getDefault() {
    return const NotificationFrequencyPreferences(
      maxDailyNotifications: '10',
      maxWeeklyNotifications: '50',
      batchSimilarNotifications: true,
      batchDelayMinutes: 5,
      respectUserActivity: true,
      cooldownMinutes: 30,
      adaptiveFrequency: true,
    );
  }

  /// Create a copy with updated fields
  NotificationFrequencyPreferences copyWith({
    String? maxDailyNotifications,
    String? maxWeeklyNotifications,
    bool? batchSimilarNotifications,
    int? batchDelayMinutes,
    bool? respectUserActivity,
    int? cooldownMinutes,
    bool? adaptiveFrequency,
  }) {
    return NotificationFrequencyPreferences(
      maxDailyNotifications: maxDailyNotifications ?? this.maxDailyNotifications,
      maxWeeklyNotifications: maxWeeklyNotifications ?? this.maxWeeklyNotifications,
      batchSimilarNotifications: batchSimilarNotifications ?? this.batchSimilarNotifications,
      batchDelayMinutes: batchDelayMinutes ?? this.batchDelayMinutes,
      respectUserActivity: respectUserActivity ?? this.respectUserActivity,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      adaptiveFrequency: adaptiveFrequency ?? this.adaptiveFrequency,
    );
  }
}
