import 'package:flutter/foundation.dart';
import '../repositories/announcements_repo.dart';
import '../models/announcement.dart';
import '../services/fcm_push_service.dart';
import '../services/notification_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final AnnouncementsRepo _repo;
  final FCMPushService _pushService;
  NotificationService? _notificationService; // optional injection
  List<Announcement> items = [];
  bool _isLoading = false;
  String? _error;

  AnnouncementProvider(this._repo, this._pushService, [this._notificationService]) {
    // Initial load to populate immediately
    _loadAllAnnouncements();
    // Live updates
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
    bool pinned = true, // force pinned by default
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
        pinned: true, // ensure pinned regardless of UI
        createdAt: DateTime.now(),
        createdBy: createdBy,
        cropTargets: const [], // remove targeting
        pushSent: false,
      );

      await _repo.createAnnouncement(announcement);

      // Ensure list updates immediately even if stream is delayed
      // ignore: unawaited_futures
      _loadAllAnnouncements();

      // Also fanout to in-app notifications (bell) without blocking the UI
      try {
        final notifs = _notificationService;
        if (notifs != null) {
          // Fire-and-forget
          // ignore: unawaited_futures
          notifs.sendAnnouncementToAllUsers(
            title: title,
            body: body,
            announcementId: announcement.id,
          );
        }
      } catch (_) {}

      // Push notifications disabled per request; rely on in-app notifications bell

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

  Future<void> _loadAllAnnouncements() async {
    try {
      final all = await _repo.getAllAnnouncements();
      items = all;
      notifyListeners();
    } catch (_) {
      // ignore load errors; stream will update if available
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