import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';

class FCMPushService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // You'll need to set this to your Firebase Cloud Messaging server key
  // This should be stored securely, not hardcoded in production
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Send push notification to a specific topic
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final message = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          'type': 'announcement',
          'topic': topic,
          ...?data,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'announcements',
            'priority': 'high',
            'default_sound': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        AppLogger.info('FCM message sent successfully: ${responseData['message_id']}');
        return true;
      } else {
        AppLogger.error('Failed to send FCM message: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error sending FCM message: $e', e);
      return false;
    }
  }

  /// Send announcement push notification
  Future<bool> sendAnnouncementPush({
    required String title,
    required String body,
    String? announcementId,
    List<String>? cropTargets,
  }) async {
    try {
      // Get current user to skip them
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;
      
      // Get all users except admins and current user
      final usersSnap = await _db.collection('users').get();
      final userIds = <String>[];
      
      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data();
        final role = (data['role'] as String?)?.toLowerCase();
        final userId = userDoc.id;
        
        // Skip admins and current user - they don't need to receive their own announcements
        if (role == 'admin' || userId == currentUserId) continue;
        
        userIds.add(userId);
      }
      
      if (userIds.isEmpty) {
        AppLogger.warning('No users to send announcement push to');
        return true; // Not an error, just no recipients
      }
      
      // Send to specific users instead of topics
      final success = await sendToUsers(
        userIds: userIds,
        title: title,
        body: body,
        data: {
          'announcementId': announcementId ?? '',
          'cropTargets': cropTargets?.join(',') ?? '',
          'type': 'announcement',
        },
      );

      return success;
    } catch (e) {
      AppLogger.error('Error sending announcement push: $e', e);
      return false;
    }
  }

  /// Send push notification to specific users
  Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get FCM tokens for all users
      final tokens = <String>[];
      for (final userId in userIds) {
        final userDoc = await _db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final userTokens = userData?['fcmTokens'] as List<dynamic>?;
          if (userTokens != null) {
            tokens.addAll(userTokens.cast<String>());
          }
        }
      }

      if (tokens.isEmpty) {
        AppLogger.warning('No FCM tokens found for users');
        return false;
      }

      // Send to each token (FCM allows up to 1000 tokens per request)
      const batchSize = 1000;
      for (int i = 0; i < tokens.length; i += batchSize) {
        final batchTokens = tokens.skip(i).take(batchSize).toList();
        
        final message = {
          'registration_ids': batchTokens,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'type': 'announcement',
            ...?data,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'announcements',
              'priority': 'high',
              'default_sound': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        };

        final response = await http.post(
          Uri.parse(_fcmUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$_serverKey',
          },
          body: json.encode(message),
        );

        if (response.statusCode != 200) {
          AppLogger.error('Failed to send FCM message to batch: ${response.statusCode} - ${response.body}');
          return false;
        }
      }

      AppLogger.info('FCM messages sent to ${tokens.length} tokens');
      return true;
    } catch (e) {
      AppLogger.error('Error sending FCM to users: $e', e);
      return false;
    }
  }

  /// Subscribe user to announcement topics
  Future<void> subscribeUserToAnnouncements(String userId, {List<String>? cropTargets}) async {
    try {
      // Subscribe to general announcements
      await FirebaseMessaging.instance.subscribeToTopic('announcements');
      
      // Subscribe to specific crop topics if provided
      if (cropTargets != null) {
        for (final crop in cropTargets) {
          final cropTopic = 'announcements_${crop.toLowerCase().replaceAll(' ', '_')}';
          await FirebaseMessaging.instance.subscribeToTopic(cropTopic);
        }
      }

      // Update user's subscription preferences in database
      await _db.collection('users').doc(userId).update({
        'announcementSubscriptions': {
          'general': true,
          'cropTargets': cropTargets ?? [],
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      AppLogger.error('Error subscribing user to announcements: $e', e);
    }
  }

  /// Unsubscribe user from announcement topics
  Future<void> unsubscribeUserFromAnnouncements(String userId, {List<String>? cropTargets}) async {
    try {
      // Unsubscribe from general announcements
      await FirebaseMessaging.instance.unsubscribeFromTopic('announcements');
      
      // Unsubscribe from specific crop topics if provided
      if (cropTargets != null) {
        for (final crop in cropTargets) {
          final cropTopic = 'announcements_${crop.toLowerCase().replaceAll(' ', '_')}';
          await FirebaseMessaging.instance.unsubscribeFromTopic(cropTopic);
        }
      }

      // Update user's subscription preferences in database
      await _db.collection('users').doc(userId).update({
        'announcementSubscriptions': {
          'general': false,
          'cropTargets': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      AppLogger.error('Error unsubscribing user from announcements: $e', e);
    }
  }

  /// Get available crop topics
  Future<List<String>> getAvailableCropTopics() async {
    try {
      // Get all unique crop targets from ingredients
      final ingredientsSnapshot = await _db.collection('ingredients').get();
      final crops = <String>{};
      
      for (final doc in ingredientsSnapshot.docs) {
        final data = doc.data();
        final recommendedFor = data['recommendedFor'] as List<dynamic>?;
        if (recommendedFor != null) {
          crops.addAll(recommendedFor.cast<String>());
        }
      }
      
      return crops.toList()..sort();
    } catch (e) {
      AppLogger.error('Error getting crop topics: $e', e);
      return [];
    }
  }
}
