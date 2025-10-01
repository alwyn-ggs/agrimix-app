import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fermentation_log.dart';
import '../models/stage_completion.dart';
import '../models/fermentation_timeline.dart';
import '../utils/logger.dart';
import '../utils/validation.dart';

/// Service for managing fermentation stages and timeline tracking
class StageManagementService {
  static final StageManagementService _instance = StageManagementService._internal();
  factory StageManagementService() => _instance;
  StageManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a single stage completion by fermentation and stage index
  Future<StageCompletion?> getStageCompletionByIndex({
    required String fermentationLogId,
    required int stageIndex,
  }) async {
    try {
      final snap = await _firestore
          .collection(StageCompletion.collectionPath)
          .where('fermentationLogId', isEqualTo: fermentationLogId)
          .where('stageIndex', isEqualTo: stageIndex)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return StageCompletion.fromMap(doc.id, doc.data());
    } catch (e, stackTrace) {
      AppLogger.error('Error getting stage completion by index: $e', e, stackTrace);
      return null;
    }
  }

  /// Append photos to a stage completion
  Future<void> addPhotosToStage({
    required String stageId,
    required List<String> photoUrls,
  }) async {
    try {
      await _firestore
          .collection(StageCompletion.collectionPath)
          .doc(stageId)
          .update({
        'photos': FieldValue.arrayUnion(photoUrls),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error adding photos to stage: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Replace notes for a stage completion
  Future<void> updateStageNotes({
    required String stageId,
    required String? notes,
  }) async {
    try {
      await _firestore
          .collection(StageCompletion.collectionPath)
          .doc(stageId)
          .update({
        'notes': notes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error updating stage notes: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Start a stage (mark as in progress)
  Future<StageCompletion> startStage({
    required String fermentationLogId,
    required int stageIndex,
    required String stageLabel,
    required String stageAction,
    required int plannedDay,
    required String userId,
  }) async {
    try {
      final stageId = _firestore.collection('stage_completions').doc().id;
      final now = DateTime.now();

      final stageCompletion = StageCompletion(
        id: stageId,
        fermentationLogId: fermentationLogId,
        stageIndex: stageIndex,
        plannedDay: plannedDay,
        stageLabel: stageLabel,
        stageAction: stageAction,
        status: StageCompletionStatus.inProgress,
        startedAt: now,
        photos: const [],
        createdAt: now,
        updatedAt: now,
      );

      // Validate before saving
      final validation = stageCompletion.validate();
      if (!validation.isValid) {
        throw Exception('Invalid stage completion: ${validation.errors.join(', ')}');
      }

      // Save to Firestore
      await _firestore
          .collection('stage_completions')
          .doc(stageId)
          .set(stageCompletion.toMap());

      // Create timeline event
      await _addTimelineEvent(
        fermentationLogId: fermentationLogId,
        type: 'stage_start',
        title: 'Started: $stageLabel',
        description: stageAction,
        stageId: stageId,
        stageIndex: stageIndex,
        userId: userId,
      );

      // Update fermentation log current stage
      await _updateFermentationLogCurrentStage(fermentationLogId, stageIndex);

      AppLogger.info('Stage started: $stageLabel for fermentation $fermentationLogId');
      return stageCompletion;
    } catch (e, stackTrace) {
      AppLogger.error('Error starting stage: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Complete a stage
  Future<StageCompletion> completeStage({
    required String stageId,
    required String actualAction,
    String? notes,
    List<String>? photos,
    Map<String, dynamic>? measurements,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();

      // Get current stage completion
      final doc = await _firestore.collection('stage_completions').doc(stageId).get();
      if (!doc.exists) {
        throw Exception('Stage completion not found: $stageId');
      }

      final currentCompletion = StageCompletion.fromMap(stageId, doc.data()!);

      // Update stage completion
      final updatedCompletion = currentCompletion.copyWith(
        status: StageCompletionStatus.completed,
        completedAt: now,
        actualAction: actualAction,
        notes: notes,
        photos: photos ?? currentCompletion.photos,
        measurements: measurements,
        completedBy: userId,
        updatedAt: now,
      );

      // Validate before saving
      final validation = updatedCompletion.validate();
      if (!validation.isValid) {
        throw Exception('Invalid stage completion: ${validation.errors.join(', ')}');
      }

      // Save to Firestore
      await _firestore
          .collection('stage_completions')
          .doc(stageId)
          .update(updatedCompletion.toMap());

      // Create timeline event
      await _addTimelineEvent(
        fermentationLogId: currentCompletion.fermentationLogId,
        type: 'stage_complete',
        title: 'Completed: ${currentCompletion.stageLabel}',
        description: actualAction,
        stageId: stageId,
        stageIndex: currentCompletion.stageIndex,
        metadata: {
          'duration': updatedCompletion.duration?.inMinutes,
          'wasOnTime': updatedCompletion.wasOnTime,
          'measurements': measurements,
        },
        userId: userId,
      );

      // Check if this was the last stage
      await _checkAndCompleteFermentation(currentCompletion.fermentationLogId);

      AppLogger.info('Stage completed: ${currentCompletion.stageLabel} for fermentation ${currentCompletion.fermentationLogId}');
      return updatedCompletion;
    } catch (e, stackTrace) {
      AppLogger.error('Error completing stage: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Skip a stage
  Future<StageCompletion> skipStage({
    required String stageId,
    required String reason,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();

      // Get current stage completion
      final doc = await _firestore.collection('stage_completions').doc(stageId).get();
      if (!doc.exists) {
        throw Exception('Stage completion not found: $stageId');
      }

      final currentCompletion = StageCompletion.fromMap(stageId, doc.data()!);

      // Update stage completion
      final updatedCompletion = currentCompletion.copyWith(
        status: StageCompletionStatus.skipped,
        completedAt: now,
        notes: reason,
        completedBy: userId,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('stage_completions')
          .doc(stageId)
          .update(updatedCompletion.toMap());

      // Create timeline event
      await _addTimelineEvent(
        fermentationLogId: currentCompletion.fermentationLogId,
        type: 'stage_skip',
        title: 'Skipped: ${currentCompletion.stageLabel}',
        description: reason,
        stageId: stageId,
        stageIndex: currentCompletion.stageIndex,
        userId: userId,
      );

      AppLogger.info('Stage skipped: ${currentCompletion.stageLabel} for fermentation ${currentCompletion.fermentationLogId}');
      return updatedCompletion;
    } catch (e, stackTrace) {
      AppLogger.error('Error skipping stage: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Mark a stage as failed
  Future<StageCompletion> failStage({
    required String stageId,
    required String reason,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();

      // Get current stage completion
      final doc = await _firestore.collection('stage_completions').doc(stageId).get();
      if (!doc.exists) {
        throw Exception('Stage completion not found: $stageId');
      }

      final currentCompletion = StageCompletion.fromMap(stageId, doc.data()!);

      // Update stage completion
      final updatedCompletion = currentCompletion.copyWith(
        status: StageCompletionStatus.failed,
        completedAt: now,
        notes: reason,
        completedBy: userId,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('stage_completions')
          .doc(stageId)
          .update(updatedCompletion.toMap());

      // Create timeline event
      await _addTimelineEvent(
        fermentationLogId: currentCompletion.fermentationLogId,
        type: 'stage_fail',
        title: 'Failed: ${currentCompletion.stageLabel}',
        description: reason,
        stageId: stageId,
        stageIndex: currentCompletion.stageIndex,
        userId: userId,
      );

      AppLogger.info('Stage failed: ${currentCompletion.stageLabel} for fermentation ${currentCompletion.fermentationLogId}');
      return updatedCompletion;
    } catch (e, stackTrace) {
      AppLogger.error('Error failing stage: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get all stage completions for a fermentation
  Future<List<StageCompletion>> getStageCompletions(String fermentationLogId) async {
    try {
      final snapshot = await _firestore
          .collection('stage_completions')
          .where('fermentationLogId', isEqualTo: fermentationLogId)
          .orderBy('stageIndex')
          .get();

      return snapshot.docs
          .map((doc) => StageCompletion.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting stage completions: $e', e, stackTrace);
      return [];
    }
  }

  /// Get timeline events for a fermentation
  Future<List<TimelineEvent>> getTimelineEvents(String fermentationLogId) async {
    try {
      final snapshot = await _firestore
          .collection('timeline_events')
          .where('fermentationLogId', isEqualTo: fermentationLogId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => TimelineEvent.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting timeline events: $e', e, stackTrace);
      return [];
    }
  }

  /// Get complete timeline for a fermentation
  Future<FermentationTimeline> getFermentationTimeline(String fermentationLogId) async {
    try {
      final stageCompletions = await getStageCompletions(fermentationLogId);
      final timelineEvents = await getTimelineEvents(fermentationLogId);

      return FermentationTimeline(
        id: fermentationLogId, // Use fermentation log ID as timeline ID
        fermentationLogId: fermentationLogId,
        events: timelineEvents,
        stageCompletions: stageCompletions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting fermentation timeline: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Add a note to the timeline
  Future<TimelineEvent> addTimelineNote({
    required String fermentationLogId,
    required String title,
    required String description,
    required String userId,
  }) async {
    try {
      final eventId = _firestore.collection('timeline_events').doc().id;
      final now = DateTime.now();

      final event = TimelineEvent(
        id: eventId,
        fermentationLogId: fermentationLogId,
        type: 'note',
        title: title,
        description: description,
        timestamp: now,
        userId: userId,
        createdAt: now,
      );

      // Validate before saving
      final validation = event.validate();
      if (!validation.isValid) {
        throw Exception('Invalid timeline event: ${validation.errors.join(', ')}');
      }

      // Save to Firestore
      await _firestore
          .collection('timeline_events')
          .doc(eventId)
          .set(event.toMap());

      AppLogger.info('Timeline note added: $title for fermentation $fermentationLogId');
      return event;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding timeline note: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Add a photo to the timeline
  Future<TimelineEvent> addTimelinePhoto({
    required String fermentationLogId,
    required String photoUrl,
    String? description,
    required String userId,
  }) async {
    try {
      final eventId = _firestore.collection('timeline_events').doc().id;
      final now = DateTime.now();

      final event = TimelineEvent(
        id: eventId,
        fermentationLogId: fermentationLogId,
        type: 'photo',
        title: 'Photo added',
        description: description,
        timestamp: now,
        metadata: {'photoUrl': photoUrl},
        userId: userId,
        createdAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('timeline_events')
          .doc(eventId)
          .set(event.toMap());

      AppLogger.info('Timeline photo added for fermentation $fermentationLogId');
      return event;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding timeline photo: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Add a measurement to the timeline
  Future<TimelineEvent> addTimelineMeasurement({
    required String fermentationLogId,
    required String measurementType,
    required dynamic value,
    required String unit,
    String? description,
    required String userId,
  }) async {
    try {
      final eventId = _firestore.collection('timeline_events').doc().id;
      final now = DateTime.now();

      final event = TimelineEvent(
        id: eventId,
        fermentationLogId: fermentationLogId,
        type: 'measurement',
        title: 'Measurement: $measurementType',
        description: description,
        timestamp: now,
        metadata: {
          'measurementType': measurementType,
          'value': value,
          'unit': unit,
        },
        userId: userId,
        createdAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('timeline_events')
          .doc(eventId)
          .set(event.toMap());

      AppLogger.info('Timeline measurement added: $measurementType for fermentation $fermentationLogId');
      return event;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding timeline measurement: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize stage completions for a new fermentation
  Future<List<StageCompletion>> initializeStages({
    required String fermentationLogId,
    required List<FermentationStage> stages,
    required String userId,
  }) async {
    try {
      final completions = <StageCompletion>[];
      final now = DateTime.now();

      for (int i = 0; i < stages.length; i++) {
        final stage = stages[i];
        final stageId = _firestore.collection('stage_completions').doc().id;

        final completion = StageCompletion(
          id: stageId,
          fermentationLogId: fermentationLogId,
          stageIndex: i,
          plannedDay: stage.day,
          stageLabel: stage.label,
          stageAction: stage.action,
          status: StageCompletionStatus.pending,
          photos: const [],
          createdAt: now,
          updatedAt: now,
        );

        // Save to Firestore
        await _firestore
            .collection('stage_completions')
            .doc(stageId)
            .set(completion.toMap());

        completions.add(completion);
      }

      // Create initial timeline event
      await _addTimelineEvent(
        fermentationLogId: fermentationLogId,
        type: 'note',
        title: 'Fermentation started',
        description: 'Initialized ${stages.length} stages',
        userId: userId,
      );

      AppLogger.info('Initialized ${stages.length} stages for fermentation $fermentationLogId');
      return completions;
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing stages: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Validate stage sequence (check for overlapping days, invalid sequences)
  ValidationResult validateStageSequence(List<FermentationStage> stages) {
    final results = <ValidationResult>[];

    // Check for overlapping days
    final daySet = <int>{};
    for (int i = 0; i < stages.length; i++) {
      final stage = stages[i];
      if (daySet.contains(stage.day)) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Stage ${i + 1} has overlapping day ${stage.day} with another stage'],
        ));
      } else {
        daySet.add(stage.day);
      }
    }

    // Check for invalid sequence (days should generally be in ascending order)
    final sortedStages = List<FermentationStage>.from(stages);
    sortedStages.sort((a, b) => a.day.compareTo(b.day));
    
    for (int i = 0; i < sortedStages.length - 1; i++) {
      final current = sortedStages[i];
      final next = sortedStages[i + 1];
      
      if (next.day - current.day > 30) {
        results.add(ValidationResult(
          isValid: false,
          warnings: ['Large gap between stage on day ${current.day} and day ${next.day}'],
        ));
      }
    }

    // Check for stages that are too close together (less than 1 day apart)
    for (int i = 0; i < sortedStages.length - 1; i++) {
      final current = sortedStages[i];
      final next = sortedStages[i + 1];
      
      if (next.day - current.day < 1) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Stages on day ${current.day} and day ${next.day} are too close together'],
        ));
      }
    }

    return ValidationResult.combine(results);
  }

  /// Private helper methods

  Future<void> _addTimelineEvent({
    required String fermentationLogId,
    required String type,
    required String title,
    String? description,
    String? stageId,
    int? stageIndex,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    try {
      final eventId = _firestore.collection('timeline_events').doc().id;
      final now = DateTime.now();

      final event = TimelineEvent(
        id: eventId,
        fermentationLogId: fermentationLogId,
        type: type,
        title: title,
        description: description,
        timestamp: now,
        stageId: stageId,
        stageIndex: stageIndex,
        metadata: metadata,
        userId: userId,
        createdAt: now,
      );

      await _firestore
          .collection('timeline_events')
          .doc(eventId)
          .set(event.toMap());
    } catch (e, stackTrace) {
      AppLogger.error('Error adding timeline event: $e', e, stackTrace);
    }
  }

  Future<void> _updateFermentationLogCurrentStage(String fermentationLogId, int stageIndex) async {
    try {
      await _firestore
          .collection('fermentation_logs')
          .doc(fermentationLogId)
          .update({
        'currentStage': stageIndex,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error updating fermentation log current stage: $e', e, stackTrace);
    }
  }

  Future<void> _checkAndCompleteFermentation(String fermentationLogId) async {
    try {
      // Get all stage completions
      final completions = await getStageCompletions(fermentationLogId);
      
      // Check if all stages are completed or skipped
      final allFinished = completions.every((completion) => 
          completion.status == StageCompletionStatus.completed ||
          completion.status == StageCompletionStatus.skipped ||
          completion.status == StageCompletionStatus.failed);

      if (allFinished && completions.isNotEmpty) {
        // Mark fermentation as done
        await _firestore
            .collection('fermentation_logs')
            .doc(fermentationLogId)
            .update({
          'status': 'done',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Add completion timeline event
        await _addTimelineEvent(
          fermentationLogId: fermentationLogId,
          type: 'note',
          title: 'Fermentation completed',
          description: 'All stages have been completed',
        );

        AppLogger.info('Fermentation completed: $fermentationLogId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking fermentation completion: $e', e, stackTrace);
    }
  }
}
