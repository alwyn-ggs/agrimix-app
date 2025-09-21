import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get FCM token for current user
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Failed to get FCM token: $e', e);
      return null;
    }
  }

  /// Save FCM token for user
  Future<void> saveToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to save FCM token: $e', e);
    }
  }

  /// Save FCM token for user (alias for saveToken)
  Future<void> saveTokenToUser(String userId, String token) async {
    await saveToken(userId, token);
  }

  /// Get all FCM tokens for a user
  Future<List<String>> getUserTokens(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final tokens = data?['fcmTokens'] as List<dynamic>?;
        return tokens?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      AppLogger.error('Failed to get user tokens: $e', e);
      return [];
    }
  }

  /// Remove FCM token for user
  Future<void> removeToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      AppLogger.error('Failed to remove FCM token: $e', e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic $topic: $e', e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic $topic: $e', e);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      AppLogger.error('Failed to request notification permission: $e', e);
      return false;
    }
  }
}