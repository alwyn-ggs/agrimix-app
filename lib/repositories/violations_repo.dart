import '../services/firestore_service.dart';
import '../models/violation.dart';

class ViolationsRepo {
  final FirestoreService _fs;

  ViolationsRepo(this._fs);

  // Create a violation report
  Future<void> createViolation(Violation violation) async {
    try {
      await _fs.createDocument(Violation.collectionPath, violation.id, violation.toMap());
    } catch (e) {
      throw Exception('Failed to create violation report: $e');
    }
  }

  // Get violation by ID
  Future<Violation?> getViolation(String violationId) async {
    try {
      final doc = await _fs.getDocument(Violation.collectionPath, violationId);
      if (doc.exists) {
        return Violation.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get violation: $e');
    }
  }

  // Update violation status
  Future<void> updateViolation(Violation violation) async {
    try {
      await _fs.updateDocument(Violation.collectionPath, violation.id, violation.toMap());
    } catch (e) {
      throw Exception('Failed to update violation: $e');
    }
  }

  // Get all violations (admin only)
  Future<List<Violation>> getAllViolations({int limit = 100}) async {
    try {
      final docs = await _fs.getDocuments(
        Violation.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Violation.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get all violations: $e');
    }
  }

  // Get violations by target type
  Future<List<Violation>> getViolationsByTargetType(ViolationTargetType targetType, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Violation.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'targetType', value: targetType.name)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Violation.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get violations by target type: $e');
    }
  }

  // Get violations by status
  Future<List<Violation>> getViolationsByStatus(ViolationStatus status, {int limit = 50}) async {
    try {
      final docs = await _fs.getDocuments(
        Violation.collectionPath,
        limit: limit,
        where: [QueryFilter(field: 'status', value: status.name)],
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      );

      return docs.map((doc) => Violation.fromMap(doc.id, doc.data()!)).toList();
    } catch (e) {
      throw Exception('Failed to get violations by status: $e');
    }
  }

  // Watch violations (real-time for admin)
  Stream<List<Violation>> watchViolations({int limit = 100}) {
    try {
      return _fs.watchDocuments(
        Violation.collectionPath,
        limit: limit,
        orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
      ).map((docs) => docs.map((doc) => Violation.fromMap(doc.id, doc.data()!)).toList());
    } catch (e) {
      throw Exception('Failed to watch violations: $e');
    }
  }

  // Check if user has already reported a target
  Future<bool> hasUserReported(String userId, ViolationTargetType targetType, String targetId) async {
    try {
      final docs = await _fs.getDocuments(
        Violation.collectionPath,
        where: [
          QueryFilter(field: 'targetType', value: targetType.name),
          QueryFilter(field: 'targetId', value: targetId),
        ],
      );

      // Check if any violation was created by this user (we'll need to add reporterId to Violation model)
      return docs.any((doc) {
        final data = doc.data()!;
        // For now, we'll check if the violation exists for this target
        // In a real implementation, you'd want to track who reported it
        return data['targetId'] == targetId && data['targetType'] == targetType.name;
      });
    } catch (e) {
      throw Exception('Failed to check if user has reported: $e');
    }
  }

  // Get violation statistics
  Future<Map<String, int>> getViolationStats() async {
    try {
      final violations = await getAllViolations(limit: 1000);
      final stats = <String, int>{
        'total': violations.length,
        'open': violations.where((v) => v.status == ViolationStatus.open).length,
        'resolved': violations.where((v) => v.status == ViolationStatus.resolved).length,
        'posts': violations.where((v) => v.targetType == ViolationTargetType.post).length,
        'recipes': violations.where((v) => v.targetType == ViolationTargetType.recipe).length,
        'users': violations.where((v) => v.targetType == ViolationTargetType.user).length,
      };
      return stats;
    } catch (e) {
      throw Exception('Failed to get violation stats: $e');
    }
  }
}
