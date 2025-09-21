import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

class FCMMessageHandler {
  final NotificationService _notificationService;

  FCMMessageHandler(this._notificationService);

  // Handle foreground messages
  void handleForegroundMessage(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Received foreground message: ${message.messageId}');
      
      // Check if it's an announcement
      if (message.data['type'] == 'announcement' || 
          message.data['topic'] == 'announcements') {
        _handleAnnouncementMessage(context, message);
      }
    });
  }

  // Handle announcement messages
  void _handleAnnouncementMessage(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Announcement';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    
    // Show local notification
    _notificationService.showNotification(
      message.hashCode,
      title,
      body,
      payload: 'announcement:${message.data['announcementId'] ?? ''}',
    );

    // Show in-app banner if app is open
    if (context.mounted) {
      _showInAppBanner(context, title, body);
    }
  }

  // Show in-app banner for announcements
  void _showInAppBanner(BuildContext context, String title, String body) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => overlayEntry.remove(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Handle notification taps
  void handleNotificationTap(String? payload) {
    if (payload != null && payload.startsWith('announcement:')) {
      final announcementId = payload.substring('announcement:'.length);
      AppLogger.info('Notification tapped for announcement: $announcementId');
      // Navigate to announcement detail or home tab
      // This will be handled by the app's navigation system
    }
  }
}
