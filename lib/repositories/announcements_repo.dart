import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementsRepo {
  final FirestoreService _fs;

  AnnouncementsRepo(this._fs);

  // CRUD Operations
  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      await _fs.createDocument(Announcement.collectionPath, announcement.id, announcement.toMap());
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  Future<Announcement?> getAnnouncement(String announcementId) async {
    try {
      final doc = await _fs.getDocument(Announcement.collectionPath, announcementId);
      if (doc.exists) {
        return Announcement.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get announcement: $e');
    }
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      await _fs.updateDocument(Announcement.collectionPath, announcement.id, announcement.toMap());
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _fs.deleteDocument(Announcement.collectionPath, announcementId);
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  // Get all announcements
  Future<List<Announcement>> getAllAnnouncements({int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit,
        orderBy: [
          QueryOrder(field: 'pinned', descending: true), // Pinned first
          QueryOrder(field: 'createdAt', descending: true),
        ],
      );

      return docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get all announcements: $e');
    }
  }

  // Real-time stream
  Stream<List<Announcement>> watchAnnouncements({int? limit}) {
    try {
      return _fs.watchDocuments(
        Announcement.collectionPath,
        limit: limit,
        orderBy: [
          QueryOrder(field: 'pinned', descending: true), // Pinned first
          QueryOrder(field: 'createdAt', descending: true),
        ],
      ).map((docs) => docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch announcements: $e');
    }
  }

  // Get pinned announcements
  Future<List<Announcement>> getPinnedAnnouncements({int limit = 10}) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'pinned', value: true)],
        orderBy: [QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get pinned announcements: $e');
    }
  }

  // Get recent announcements
  Future<List<Announcement>> getRecentAnnouncements({int limit = 10}) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit,
        orderBy: [QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get recent announcements: $e');
    }
  }

  // Pin/Unpin announcement
  Future<void> pinAnnouncement(String announcementId) async {
    try {
      await _fs.updateDocument(Announcement.collectionPath, announcementId, {
        'pinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to pin announcement: $e');
    }
  }

  Future<void> unpinAnnouncement(String announcementId) async {
    try {
      await _fs.updateDocument(Announcement.collectionPath, announcementId, {
        'pinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unpin announcement: $e');
    }
  }

  // Search announcements
  Future<List<Announcement>> searchAnnouncements(String searchTerm, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit * 2, // Get more to filter
        orderBy: [QueryOrder(field: 'createdAt', descending: true)],
      );

      final announcements = docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
      
      // Filter announcements that contain the search term
      final filteredAnnouncements = announcements.where((announcement) => 
        announcement.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
        announcement.body.toLowerCase().contains(searchTerm.toLowerCase())
      ).take(limit).toList();

      return filteredAnnouncements;
    } catch (e) {
      throw Exception('Failed to search announcements: $e');
    }
  }

  // Get announcements by creator
  Future<List<Announcement>> getAnnouncementsByCreator(String createdBy, {int limit = 20}) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'createdBy', value: createdBy)],
        orderBy: [QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get announcements by creator: $e');
    }
  }

  // Get announcement statistics
  Future<Map<String, int>> getAnnouncementStats() async {
    try {
      final announcements = await getAllAnnouncements(limit: 1000);
      final stats = <String, int>{
        'total': announcements.length,
        'pinned': announcements.where((a) => a.pinned).length,
        'unpinned': announcements.where((a) => !a.pinned).length,
      };
      return stats;
    } catch (e) {
      throw Exception('Failed to get announcement stats: $e');
    }
  }

  // Batch create announcements
  Future<void> batchCreateAnnouncements(List<Announcement> announcements) async {
    try {
      final batch = _fs.batch();
      for (final announcement in announcements) {
        final docRef = _fs.db.collection(Announcement.collectionPath).doc(announcement.id);
        batch.set(docRef, announcement.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch create announcements: $e');
    }
  }

  // Get announcements by date range
  Future<List<Announcement>> getAnnouncementsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  }) async {
    try {
      final docs = await _fs.getDocuments(
        Announcement.collectionPath,
        limit: limit,
        orderBy: [QueryOrder(field: 'createdAt', descending: true)],
      );

      final announcements = docs.map((doc) => Announcement.fromMap(doc.id, doc.data()!)).toList();
      
      return announcements.where((announcement) => 
        announcement.createdAt.isAfter(startDate) && announcement.createdAt.isBefore(endDate)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get announcements by date range: $e');
    }
  }
}