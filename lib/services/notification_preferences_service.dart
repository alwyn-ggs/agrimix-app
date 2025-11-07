import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_preferences.dart';
import '../utils/logger.dart';

/// Service for managing user notification preferences and settings
class NotificationPreferencesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get user notification preferences
  Future<NotificationPreferences?> getUserPreferences(String userId) async {
    try {
      if (userId.isEmpty) {
        AppLogger.error('User ID is empty');
        return null;
      }

      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        // Create default preferences if they don't exist
        AppLogger.info('Creating default notification preferences for user: $userId');
        final defaultPrefs = NotificationPreferences.getDefault(userId);
        await _savePreferences(defaultPrefs);
        return defaultPrefs;
      }

      final prefs = NotificationPreferences.fromFirestore(doc);
      AppLogger.info('Loaded notification preferences for user: $userId');
      return prefs;
    } catch (e) {
      AppLogger.error('Failed to get notification preferences for user $userId: $e', e);
      return null;
    }
  }

  /// Save user notification preferences
  Future<bool> savePreferences(NotificationPreferences preferences) async {
    try {
      await _savePreferences(preferences);
      return true;
    } catch (e) {
      AppLogger.error('Failed to save notification preferences: $e', e);
      return false;
    }
  }

  /// Internal method to save preferences to Firestore
  Future<void> _savePreferences(NotificationPreferences preferences) async {
    await _db
        .collection('users')
        .doc(preferences.userId)
        .collection('preferences')
        .doc('notifications')
        .set(preferences.toFirestore());
  }

  /// Update specific notification type preference
  Future<bool> updateNotificationType(String userId, String type, bool enabled) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedTypes = Map<String, bool>.from(prefs.notificationTypes);
      updatedTypes[type] = enabled;

      final updatedPrefs = prefs.copyWith(
        notificationTypes: updatedTypes,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update notification type: $e', e);
      return false;
    }
  }

  /// Update channel preference
  Future<bool> updateChannel(String userId, String channel, bool enabled) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedChannels = Map<String, bool>.from(prefs.channels);
      updatedChannels[channel] = enabled;

      final updatedPrefs = prefs.copyWith(
        channels: updatedChannels,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update channel preference: $e', e);
      return false;
    }
  }

  /// Update time preferences
  Future<bool> updateTimePreferences(
    String userId,
    NotificationTimePreferences timePreferences,
  ) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedPrefs = prefs.copyWith(
        timePreferences: timePreferences,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update time preferences: $e', e);
      return false;
    }
  }

  /// Update frequency preferences
  Future<bool> updateFrequencyPreferences(
    String userId,
    NotificationFrequencyPreferences frequencyPreferences,
  ) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedPrefs = prefs.copyWith(
        frequencyPreferences: frequencyPreferences,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update frequency preferences: $e', e);
      return false;
    }
  }

  /// Update quiet hours settings
  Future<bool> updateQuietHours(
    String userId, {
    required bool enabled,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? quietDays,
  }) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedPrefs = prefs.copyWith(
        quietHoursEnabled: enabled,
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
        quietDays: quietDays,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update quiet hours: $e', e);
      return false;
    }
  }

  /// Update digest settings
  Future<bool> updateDigestSettings(
    String userId, {
    required bool enabled,
    required String frequency,
    required String time,
  }) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedPrefs = prefs.copyWith(
        digestEnabled: enabled,
        digestFrequency: frequency,
        digestTime: time,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to update digest settings: $e', e);
      return false;
    }
  }

  /// Toggle all notifications on/off
  Future<bool> toggleAllNotifications(String userId, bool enabled) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      final updatedPrefs = prefs.copyWith(
        enabled: enabled,
        updatedAt: DateTime.now(),
      );

      return await savePreferences(updatedPrefs);
    } catch (e) {
      AppLogger.error('Failed to toggle all notifications: $e', e);
      return false;
    }
  }

  /// Reset to default preferences
  Future<bool> resetToDefaults(String userId) async {
    try {
      final defaultPrefs = NotificationPreferences.getDefault(userId);
      return await savePreferences(defaultPrefs);
    } catch (e) {
      AppLogger.error('Failed to reset preferences to defaults: $e', e);
      return false;
    }
  }

  /// Check if user should receive notification based on preferences
  Future<bool> shouldSendNotification(
    String userId,
    String notificationType, {
    DateTime? scheduledTime,
  }) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return false;

      // Check if notifications are enabled
      if (!prefs.enabled) return false;

      // Check if this notification type is enabled
      if (!(prefs.notificationTypes[notificationType] ?? false)) return false;

      // Check if push notifications are enabled
      if (!(prefs.channels['push'] ?? false)) return false;

      // Check quiet hours
      if (prefs.quietHoursEnabled && scheduledTime != null) {
        if (_isInQuietHours(scheduledTime, prefs)) return false;
      }

      // Check if it's a preferred day
      if (scheduledTime != null) {
        final dayName = _getDayName(scheduledTime.weekday);
        if (!prefs.timePreferences.preferredDays.contains(dayName)) return false;
      }

      // Check if it's a preferred hour
      if (scheduledTime != null) {
        final hour = scheduledTime.hour;
        if (!prefs.timePreferences.preferredHours.contains(hour)) return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to check notification preferences: $e', e);
      return false;
    }
  }

  /// Check if current time is within quiet hours
  bool _isInQuietHours(DateTime time, NotificationPreferences prefs) {
    if (prefs.quietHoursStart == null || prefs.quietHoursEnd == null) return false;

    final dayName = _getDayName(time.weekday);
    if (!prefs.quietDays.contains(dayName)) return false;

    final timeOfDay = TimeOfDay.fromDateTime(time);
    final startTime = TimeOfDay.fromDateTime(prefs.quietHoursStart!);
    final endTime = TimeOfDay.fromDateTime(prefs.quietHoursEnd!);

    final currentMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // Same day quiet hours
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight quiet hours
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
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

  /// Get optimal send time for user based on preferences
  Future<DateTime?> getOptimalSendTime(String userId) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Find next preferred hour today
      for (final hour in prefs.timePreferences.preferredHours) {
        final candidateTime = today.add(Duration(hours: hour));
        if (candidateTime.isAfter(now)) {
          return candidateTime;
        }
      }

      // If no preferred hour today, find next preferred day
      for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
        final candidateDate = today.add(Duration(days: dayOffset));
        final dayName = _getDayName(candidateDate.weekday);
        
        if (prefs.timePreferences.preferredDays.contains(dayName)) {
          final firstPreferredHour = prefs.timePreferences.preferredHours.first;
          return candidateDate.add(Duration(hours: firstPreferredHour));
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get optimal send time: $e', e);
      return null;
    }
  }

  /// Get notification frequency limits
  Future<Map<String, int>> getFrequencyLimits(String userId) async {
    try {
      final prefs = await getUserPreferences(userId);
      if (prefs == null) return {'daily': 10, 'weekly': 50};

      return {
        'daily': int.tryParse(prefs.frequencyPreferences.maxDailyNotifications) ?? 10,
        'weekly': int.tryParse(prefs.frequencyPreferences.maxWeeklyNotifications) ?? 50,
      };
    } catch (e) {
      AppLogger.error('Failed to get frequency limits: $e', e);
      return {'daily': 10, 'weekly': 50};
    }
  }
}

/// TimeOfDay helper class for time calculations
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
