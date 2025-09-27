import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/messaging_service.dart';
import 'utils/logger.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI overlay style to prevent status bar overlap
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    // Initialize Firebase with a more generous timeout to accommodate slow startups
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw Exception('Firebase initialization timed out');
      },
    );
    
    // Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize notification service
    final messagingService = MessagingService();
    final notificationService = NotificationService(messagingService);
    try {
      await notificationService.init();
      AppLogger.info('Notification service initialized successfully');
    } catch (error) {
      AppLogger.warning('Warning: Notification service initialization failed: $error');
    }
    
    // Request notification permissions on mobile only (Android/iOS)
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
      // Convert to Future<void> so timeout's onTimeout can return void
      FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .then((_) {})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.warning('Warning: Notification permission request timed out');
            },
          )
          .catchError((error) {
            AppLogger.warning('Warning: Notification permission request failed: $error');
          });
    }
    
    runApp(const AgriMixAppRoot());
  } catch (e) {
    AppLogger.error('Firebase initialization error: $e', e);
    // If Firebase fails to initialize, show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize Firebase'),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

