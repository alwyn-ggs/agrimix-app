import 'package:flutter/foundation.dart';
import '../repositories/announcements_repo.dart';
import '../models/announcement.dart';
import '../services/fcm_push_service.dart';
import '../services/notification_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final AnnouncementsRepo _repo;
  final FCMPushService _pushService;
  final NotificationService? _notificationService; // optional injection
  List<Announcement> items = [];
  bool _isLoading = false;
  String? _error;

  AnnouncementProvider(this._repo, this._pushService, [this._notificationService]) {
    _repo.watchAnnouncements().listen((v) { 
      items = v; 
      notifyListeners(); 
    });
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Create a new announcement with optional push notification
  Future<bool> createAnnouncement({
    required String title,
    required String body,
    required String createdBy,
    bool pinned = false,
    List<String> cropTargets = const [],
    bool sendPush = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final announcement = Announcement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        pinned: pinned,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        cropTargets: cropTargets,
        pushSent: false,
      );

      await _repo.createAnnouncement(announcement);

      // Also fanout to in-app notifications (bell) and local notifications
      try {
        final notifs = _notificationService;
        if (notifs != null) {
          // Send to notification bell (database records)
          await notifs.sendAnnouncementToAllUsers(
            title: title,
            body: body,
            announcementId: announcement.id,
          );
          
          // Send local notifications to all users
          await notifs.sendAnnouncementNotification(
            title: title,
            body: body,
            announcementId: announcement.id,
          );
        }
      } catch (_) {}

      // Send push notification if requested
      if (sendPush) {
        final pushSuccess = await _pushService.sendAnnouncementPush(
          title: title,
          body: body,
          announcementId: announcement.id,
          cropTargets: cropTargets.isNotEmpty ? cropTargets : null,
        );

        // Update announcement with push status
        if (pushSuccess) {
          await _repo.updateAnnouncement(announcement.copyWith(pushSent: true));
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing announcement
  Future<bool> updateAnnouncement(Announcement announcement) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.updateAnnouncement(announcement);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.deleteAnnouncement(announcementId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle pin status of an announcement
  Future<bool> togglePin(String announcementId) async {
    try {
      final announcement = items.firstWhere((a) => a.id == announcementId);
      final updatedAnnouncement = announcement.copyWith(pinned: !announcement.pinned);
      
      return await updateAnnouncement(updatedAnnouncement);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Send push notification for an existing announcement
  Future<bool> sendPushNotification(String announcementId) async {
    try {
      final announcement = items.firstWhere((a) => a.id == announcementId);
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      final pushSuccess = await _pushService.sendAnnouncementPush(
        title: announcement.title,
        body: announcement.body,
        announcementId: announcement.id,
        cropTargets: announcement.cropTargets.isNotEmpty ? announcement.cropTargets : null,
      );

      // Also send local notifications
      try {
        final notifs = _notificationService;
        if (notifs != null) {
          await notifs.sendAnnouncementNotification(
            title: announcement.title,
            body: announcement.body,
            announcementId: announcement.id,
          );
        }
      } catch (_) {}

      // Update announcement with push status
      if (pushSuccess) {
        await _repo.updateAnnouncement(announcement.copyWith(pushSent: true));
      }

      _isLoading = false;
      notifyListeners();
      return pushSuccess;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get available crop targets
  Future<List<String>> getAvailableCropTargets() async {
    try {
      return await _pushService.getAvailableCropTopics();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}