import 'package:flutter/material.dart';
import 'navigation_service.dart';

/// Centralized user feedback service to show SnackBars conditionally and deduplicate messages
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  // Keep last shown message and timestamp to avoid spamming the same message rapidly
  String? _lastMessage;
  DateTime? _lastShownAt;

  /// Show a SnackBar if appropriate. Dedupe same message within [dedupeWindow].
  void showSnack(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Duration dedupeWindow = const Duration(seconds: 2),
  }) {
    // Avoid empty messages
    if (message.trim().isEmpty) return;

    // Dedupe identical messages in a short window
    final now = DateTime.now();
    if (_lastMessage == message && _lastShownAt != null) {
      if (now.difference(_lastShownAt!) < dedupeWindow) {
        return;
      }
    }

    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    // If there's no ScaffoldMessenger available, skip showing to avoid random popups
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _lastMessage = message;
    _lastShownAt = now;
  }
}


