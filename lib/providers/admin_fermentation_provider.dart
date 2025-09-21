import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fermentation_log.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class AdminFermentationProvider extends ChangeNotifier {
  List<FermentationLog> _allLogs = [];
  List<AppUser> _farmers = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<FermentationLog>>? _logsSubscription;

  AdminFermentationProvider();

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }

  List<FermentationLog> get allLogs => _allLogs;
  List<AppUser> get farmers => _farmers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Start monitoring all fermentation logs
  void startMonitoring() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _logsSubscription?.cancel();
    
    // Watch all fermentation logs
    _logsSubscription = _watchAllFermentationLogs().listen(
      (logs) {
        _allLogs = logs;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Stream to watch all fermentation logs
  Stream<List<FermentationLog>> _watchAllFermentationLogs() {
    return FirebaseFirestore.instance
        .collection(FermentationLog.collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final logs = <FermentationLog>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final log = FermentationLog.fromMap(doc.id, data);
              logs.add(log);
                        } catch (e) {
              AppLogger.error('Error parsing fermentation log ${doc.id}: $e', e);
              // Skip this log and continue with others
            }
          }
          return logs;
        });
  }

  // Get logs by status
  List<FermentationLog> getLogsByStatus(FermentationStatus status) {
    return _allLogs.where((log) => log.status == status).toList();
  }

  // Get logs by method
  List<FermentationLog> getLogsByMethod(FermentationMethod method) {
    return _allLogs.where((log) => log.method == method).toList();
  }

  // Get logs by farmer
  List<FermentationLog> getLogsByFarmer(String farmerUid) {
    return _allLogs.where((log) => log.ownerUid == farmerUid).toList();
  }

  // Get farmer info for a log
  AppUser? getFarmerForLog(String farmerUid) {
    try {
      return _farmers.firstWhere(
        (farmer) => farmer.uid == farmerUid,
        orElse: () => AppUser(
          uid: farmerUid,
          name: 'Unknown Farmer',
          email: 'unknown@example.com',
          role: 'farmer',
          approved: false,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      // Return a default farmer if not found
      return AppUser(
        uid: farmerUid,
        name: 'Unknown Farmer',
        email: 'unknown@example.com',
        role: 'farmer',
        approved: false,
        createdAt: DateTime.now(),
      );
    }
  }

  // Chart data for active vs completed logs over time
  Map<String, dynamic> getActiveVsCompletedOverTime() {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    
    final activeLogs = _allLogs.where((log) => 
      log.status == FermentationStatus.active && 
      log.createdAt.isAfter(last30Days)
    ).toList();
    
    final completedLogs = _allLogs.where((log) => 
      log.status == FermentationStatus.done && 
      log.createdAt.isAfter(last30Days)
    ).toList();

    // Group by day
    final Map<String, int> activeByDay = {};
    final Map<String, int> completedByDay = {};

    for (int i = 0; i < 30; i++) {
      final date = last30Days.add(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      activeByDay[dateKey] = 0;
      completedByDay[dateKey] = 0;
    }

    // Count active logs by creation date
    for (final log in activeLogs) {
      final dateKey = '${log.createdAt.month}/${log.createdAt.day}';
      activeByDay[dateKey] = (activeByDay[dateKey] ?? 0) + 1;
    }

    // Count completed logs by completion date (using createdAt as proxy)
    for (final log in completedLogs) {
      final dateKey = '${log.createdAt.month}/${log.createdAt.day}';
      completedByDay[dateKey] = (completedByDay[dateKey] ?? 0) + 1;
    }

    return {
      'active': activeByDay,
      'completed': completedByDay,
      'dates': activeByDay.keys.toList(),
    };
  }

  // Chart data for method breakdown
  Map<String, int> getMethodBreakdown() {
    final ffjCount = _allLogs.where((log) => log.method == FermentationMethod.FFJ).length;
    final fpjCount = _allLogs.where((log) => log.method == FermentationMethod.FPJ).length;
    
    return {
      'FFJ': ffjCount,
      'FPJ': fpjCount,
    };
  }

  // Chart data for average completion time
  Map<String, double> getAverageCompletionTime() {
    final completedLogs = _allLogs.where((log) => log.status == FermentationStatus.done).toList();
    
    if (completedLogs.isEmpty) {
      return {'FFJ': 0.0, 'FPJ': 0.0};
    }

    final ffjLogs = completedLogs.where((log) => log.method == FermentationMethod.FFJ).toList();
    final fpjLogs = completedLogs.where((log) => log.method == FermentationMethod.FPJ).toList();

    double ffjAvg = 0.0;
    double fpjAvg = 0.0;

    if (ffjLogs.isNotEmpty) {
      final ffjTimes = ffjLogs.map((log) => 
        log.stages.isNotEmpty ? log.stages.last.day.toDouble() : 0.0
      ).toList();
      ffjAvg = ffjTimes.reduce((a, b) => a + b) / ffjTimes.length;
    }

    if (fpjLogs.isNotEmpty) {
      final fpjTimes = fpjLogs.map((log) => 
        log.stages.isNotEmpty ? log.stages.last.day.toDouble() : 0.0
      ).toList();
      fpjAvg = fpjTimes.reduce((a, b) => a + b) / fpjTimes.length;
    }

    return {
      'FFJ': ffjAvg,
      'FPJ': fpjAvg,
    };
  }

  // Chart data for most-used ingredients
  Map<String, int> getMostUsedIngredients({int limit = 10}) {
    final Map<String, int> ingredientCounts = {};
    
    for (final log in _allLogs) {
      for (final ingredient in log.ingredients) {
        ingredientCounts[ingredient.name] = (ingredientCounts[ingredient.name] ?? 0) + 1;
      }
    }

    // Sort by count and take top N
    final sortedIngredients = Map.fromEntries(
      ingredientCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );

    return Map.fromEntries(
      sortedIngredients.entries.take(limit)
    );
  }

  // Get fermentation statistics
  Map<String, int> getStatistics() {
    return {
      'total': _allLogs.length,
      'active': getLogsByStatus(FermentationStatus.active).length,
      'completed': getLogsByStatus(FermentationStatus.done).length,
      'cancelled': getLogsByStatus(FermentationStatus.cancelled).length,
      'ffj': getLogsByMethod(FermentationMethod.FFJ).length,
      'fpj': getLogsByMethod(FermentationMethod.FPJ).length,
    };
  }

  // Get logs by date range
  List<FermentationLog> getLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _allLogs.where((log) => 
      log.createdAt.isAfter(startDate) && log.createdAt.isBefore(endDate)
    ).toList();
  }

  // Get overdue fermentations
  List<FermentationLog> getOverdueLogs() {
    final now = DateTime.now();
    return _allLogs.where((log) {
      if (log.status != FermentationStatus.active || log.stages.isEmpty) return false;
      if (log.currentStage >= log.stages.length) return false;
      
      final nextStage = log.stages[log.currentStage];
      final stageDate = log.startAt.add(Duration(days: nextStage.day));
      return stageDate.isBefore(now);
    }).toList();
  }

  // Set farmers list (called from admin provider)
  void setFarmers(List<AppUser> farmers) {
    _farmers = farmers;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
