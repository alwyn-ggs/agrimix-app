import 'package:flutter/foundation.dart';
import 'dart:io';
import '../repositories/fermentation_repo.dart';
import '../services/notification_service.dart';
import '../models/fermentation_log.dart';

class FermentationProvider extends ChangeNotifier {
  final FermentationRepo _repo;
  final NotificationService _notifs;
  List<FermentationLog> myLogs = [];
  bool _isLoading = false;
  String? _error;

  FermentationProvider(this._repo, this._notifs);

  bool get isLoading => _isLoading;
  String? get error => _error;

  void watch(String userId) {
    _repo.watchMyLogs(userId).listen(
      (v) {
        myLogs = v;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> createFermentationLog(FermentationLog log) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.createFermentationLog(log);
      
      // Schedule notifications if enabled
      if (log.alertsEnabled) {
        await _notifs.scheduleFermentationNotifications(
          log.id,
          log.title,
          log.stages.map((s) => s.toMap()).toList(),
          log.startAt,
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFermentationLog(FermentationLog log) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.updateFermentationLog(log);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markStageCompleted({
    required String logId,
    required int stageIndex,
    String? note,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.markStageCompleted(
        logId: logId,
        completedStageIndex: stageIndex,
        note: note,
      );

      // Check if fermentation is complete
      final log = myLogs.firstWhere((l) => l.id == logId);
      if (stageIndex + 1 >= log.stages.length) {
        // Fermentation is complete
        await _notifs.scheduleCompletionNotification(logId, log.title);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFermentationStatus(String logId, FermentationStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.updateFermentationStatus(logId, status);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAlerts(String logId, bool enabled) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.toggleFermentationAlerts(logId, enabled);
      
      if (enabled) {
        final log = myLogs.firstWhere((l) => l.id == logId);
        await _notifs.scheduleFermentationNotifications(
          log.id,
          log.title,
          log.stages.map((s) => s.toMap()).toList(),
          log.startAt,
        );
      } else {
        await _notifs.cancelFermentationNotifications(logId);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPhotos(String logId, List<File> photoFiles, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.addPhotosToFermentationLog(logId, photoFiles, userId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removePhoto(String logId, String photoUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.removePhotoFromFermentationLog(logId, photoUrl);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotes(String logId, String notes) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.updateFermentationNotes(logId, notes);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFermentationLog(String logId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel notifications first
      await _notifs.cancelFermentationNotifications(logId);
      
      // Delete the log
      await _repo.deleteFermentationLog(logId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get active fermentations
  List<FermentationLog> get activeLogs => myLogs.where((log) => log.status == FermentationStatus.active).toList();

  // Get completed fermentations
  List<FermentationLog> get completedLogs => myLogs.where((log) => log.status == FermentationStatus.done).toList();

  // Get overdue fermentations
  List<FermentationLog> get overdueLogs {
    final now = DateTime.now();
    return myLogs.where((log) {
      if (log.status != FermentationStatus.active || log.stages.isEmpty) return false;
      if (log.currentStage >= log.stages.length) return false;
      
      final nextStage = log.stages[log.currentStage];
      final stageDate = log.startAt.add(Duration(days: nextStage.day));
      return stageDate.isBefore(now);
    }).toList();
  }

  // Get fermentation statistics
  Map<String, int> get stats {
    return {
      'total': myLogs.length,
      'active': activeLogs.length,
      'completed': completedLogs.length,
      'overdue': overdueLogs.length,
      'ffj': myLogs.where((log) => log.method == FermentationMethod.FFJ).length,
      'fpj': myLogs.where((log) => log.method == FermentationMethod.FPJ).length,
    };
  }

  Future<void> remind(String title, String body) => _notifs.showSimple(title, body);

  void clearError() {
    _error = null;
    notifyListeners();
  }
}