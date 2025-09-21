import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/fermentation_log.dart';

class FermentationRepo {
  final FirestoreService _fs;
  final StorageService _storage;

  FermentationRepo(this._fs, this._storage);

  // CRUD Operations
  Future<void> createFermentationLog(FermentationLog log) async {
    try {
      await _fs.createDocument(FermentationLog.collectionPath, log.id, log.toMap());
    } catch (e) {
      throw Exception('Failed to create fermentation log: $e');
    }
  }

  Future<FermentationLog?> getFermentationLog(String logId) async {
    try {
      final doc = await _fs.getDocument(FermentationLog.collectionPath, logId);
      if (doc.exists) {
        return FermentationLog.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get fermentation log: $e');
    }
  }

  Future<void> updateFermentationLog(FermentationLog log) async {
    try {
      await _fs.updateDocument(FermentationLog.collectionPath, log.id, log.toMap());
    } catch (e) {
      throw Exception('Failed to update fermentation log: $e');
    }
  }

  Future<void> deleteFermentationLog(String logId) async {
    try {
      await _fs.deleteDocument(FermentationLog.collectionPath, logId);
    } catch (e) {
      throw Exception('Failed to delete fermentation log: $e');
    }
  }

  // Get user's fermentation logs
  Future<List<FermentationLog>> getUserFermentationLogs(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    FermentationStatus? status,
    FermentationMethod? method,
  }) async {
    try {
      final where = <QueryFilter>[QueryFilter(field: 'ownerUid', value: userId)];
      if (status != null) {
        where.add(QueryFilter(field: 'status', value: status.name));
      }
      if (method != null) {
        where.add(QueryFilter(field: 'method', value: method == FermentationMethod.fpj ? 'fpj' : 'ffj'));
      }

      final docs = await _fs.getDocuments(
        FermentationLog.collectionPath,
        limit: limit,
        startAfter: startAfter,
        where: where,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => FermentationLog.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get user fermentation logs: $e');
    }
  }

  // Real-time streams
  Stream<List<FermentationLog>> watchUserFermentationLogs(
    String userId, {
    int? limit,
    FermentationStatus? status,
    FermentationMethod? method,
  }) {
    try {
      final where = <QueryFilter>[QueryFilter(field: 'ownerUid', value: userId)];
      if (status != null) {
        where.add(QueryFilter(field: 'status', value: status.name));
      }
      if (method != null) {
        where.add(QueryFilter(field: 'method', value: method == FermentationMethod.fpj ? 'fpj' : 'ffj'));
      }

      return _fs.watchDocuments(
        FermentationLog.collectionPath,
        limit: limit,
        where: where,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      ).map((docs) => docs.map((doc) => FermentationLog.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch user fermentation logs: $e');
    }
  }

  // Legacy method for backward compatibility
  Stream<List<FermentationLog>> watchMyLogs(String userId) => watchUserFermentationLogs(userId);

  // Get active fermentation logs
  Future<List<FermentationLog>> getActiveFermentationLogs(String userId) async {
    try {
      return getUserFermentationLogs(
        userId,
        status: FermentationStatus.active,
        limit: 50,
      );
    } catch (e) {
      throw Exception('Failed to get active fermentation logs: $e');
    }
  }

  // Update fermentation stage
  Future<void> updateFermentationStage(String logId, int newStage) async {
    try {
      await _fs.updateDocument(FermentationLog.collectionPath, logId, {
        'currentStage': newStage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update fermentation stage: $e');
    }
  }

  // Append a history entry to the fermentation log
  Future<void> addHistoryEntry({
    required String logId,
    required int stageIndex,
    String? note,
  }) async {
    try {
      final entry = {
        'stageIndex': stageIndex,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _fs.db
          .collection(FermentationLog.collectionPath)
          .doc(logId)
          .update({'history': FieldValue.arrayUnion([entry])});
    } catch (e) {
      // If history field doesn't exist, set it
      try {
        await _fs.db
            .collection(FermentationLog.collectionPath)
            .doc(logId)
            .set({'history': [
              {
                'stageIndex': stageIndex,
                'note': note,
                'createdAt': FieldValue.serverTimestamp(),
              }
            ]}, SetOptions(merge: true));
      } catch (e2) {
        throw Exception('Failed to add history entry: $e2');
      }
    }
  }

  // Mark stage as completed: updates currentStage and appends to history
  Future<void> markStageCompleted({
    required String logId,
    required int completedStageIndex,
    String? note,
  }) async {
    try {
      await _fs.runTransaction((tx) async {
        final ref = _fs.db.collection(FermentationLog.collectionPath).doc(logId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Log not found');
        final data = snap.data()!;
        final currentStage = (data['currentStage'] ?? 0) as int;
        final nextStage = (completedStageIndex + 1 > currentStage) ? completedStageIndex + 1 : currentStage + 1;
        tx.update(ref, {
          'currentStage': nextStage,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await addHistoryEntry(logId: logId, stageIndex: completedStageIndex, note: note);
    } catch (e) {
      throw Exception('Failed to mark stage completed: $e');
    }
  }

  // Update fermentation status
  Future<void> updateFermentationStatus(String logId, FermentationStatus status) async {
    try {
      await _fs.updateDocument(FermentationLog.collectionPath, logId, {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update fermentation status: $e');
    }
  }

  // Add photos to fermentation log
  Future<void> addPhotosToFermentationLog(String logId, List<File> photoFiles, String userId) async {
    try {
      final photoUrls = await _storage.uploadFermentationImages(
        imageFiles: photoFiles,
        userId: userId,
      );

      final log = await getFermentationLog(logId);
      if (log != null) {
        final updatedPhotos = [...log.photos, ...photoUrls];
        await _fs.updateDocument(FermentationLog.collectionPath, logId, {
          'photos': updatedPhotos,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add photos to fermentation log: $e');
    }
  }

  // Remove photo from fermentation log
  Future<void> removePhotoFromFermentationLog(String logId, String photoUrl) async {
    try {
      final log = await getFermentationLog(logId);
      if (log != null) {
        final updatedPhotos = log.photos.where((url) => url != photoUrl).toList();
        await _fs.updateDocument(FermentationLog.collectionPath, logId, {
          'photos': updatedPhotos,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Delete photo from storage
        await _storage.deleteFileByUrl(photoUrl);
      }
    } catch (e) {
      throw Exception('Failed to remove photo from fermentation log: $e');
    }
  }

  // Update fermentation notes
  Future<void> updateFermentationNotes(String logId, String notes) async {
    try {
      await _fs.updateDocument(FermentationLog.collectionPath, logId, {
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update fermentation notes: $e');
    }
  }

  // Toggle alerts for fermentation log
  Future<void> toggleFermentationAlerts(String logId, bool alertsEnabled) async {
    try {
      await _fs.updateDocument(FermentationLog.collectionPath, logId, {
        'alertsEnabled': alertsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle fermentation alerts: $e');
    }
  }

  // Get fermentation logs by recipe
  Future<List<FermentationLog>> getFermentationLogsByRecipe(String recipeId, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        FermentationLog.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'recipeId', value: recipeId)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => FermentationLog.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get fermentation logs by recipe: $e');
    }
  }

  // Get fermentation statistics
  Future<Map<String, int>> getFermentationStats(String userId) async {
    try {
      final logs = await getUserFermentationLogs(userId, limit: 1000);
      final stats = <String, int>{
        'total': logs.length,
        'active': logs.where((log) => log.status == FermentationStatus.active).length,
        'completed': logs.where((log) => log.status == FermentationStatus.done).length,
        'cancelled': logs.where((log) => log.status == FermentationStatus.cancelled).length,
        'ffj': logs.where((log) => log.method == FermentationMethod.FFJ).length,
        'fpj': logs.where((log) => log.method == FermentationMethod.FPJ).length,
      };
      return stats;
    } catch (e) {
      throw Exception('Failed to get fermentation stats: $e');
    }
  }

  // Search fermentation logs
  Future<List<FermentationLog>> searchFermentationLogs(
    String userId,
    String searchTerm, {
    int limit = 20,
  }) async {
    try {
      final logs = await getUserFermentationLogs(userId, limit: 1000);
      return logs.where((log) => 
        log.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
        log.notes?.toLowerCase().contains(searchTerm.toLowerCase()) == true
      ).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search fermentation logs: $e');
    }
  }

  // Get fermentation logs by date range
  Future<List<FermentationLog>> getFermentationLogsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  }) async {
    try {
      final docs = await _fs.getDocuments(
        FermentationLog.collectionPath,
        limit: limit,
        where: [
          QueryFilter(field: 'ownerUid', value: userId),
        ],
        orderBy: [const QueryOrder(field: 'startAt', descending: false)],
      );

      final logs = docs.map((doc) => FermentationLog.fromMap(doc.id, doc.data()!)).toList();
      
      return logs.where((log) => 
        log.startAt.isAfter(startDate) && log.startAt.isBefore(endDate)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get fermentation logs by date range: $e');
    }
  }
}