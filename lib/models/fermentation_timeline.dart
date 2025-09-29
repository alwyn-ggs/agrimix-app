import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation.dart';
import '../utils/logger.dart';
import 'stage_completion.dart';

/// Represents a timeline event in the fermentation process
class TimelineEvent {
  final String id;
  final String fermentationLogId;
  final String type; // 'stage_start', 'stage_complete', 'stage_skip', 'stage_fail', 'note', 'photo', 'measurement'
  final String title;
  final String? description;
  final DateTime timestamp;
  final String? stageId; // Reference to stage completion if applicable
  final int? stageIndex; // Index of the stage if applicable
  final Map<String, dynamic>? metadata; // Additional data specific to event type
  final String? userId; // User who triggered the event
  final DateTime createdAt;

  TimelineEvent({
    required this.id,
    required this.fermentationLogId,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.stageId,
    this.stageIndex,
    this.metadata,
    this.userId,
    required this.createdAt,
  });

  static const String collectionPath = 'timeline_events';
  static String docPath(String id) => 'timeline_events/$id';
  static String fermentationScopedPath(String fermentationLogId) => 
      'fermentation_logs/$fermentationLogId/timeline_events';

  factory TimelineEvent.fromMap(String id, Map<String, dynamic> map) => TimelineEvent(
        id: id,
        fermentationLogId: map['fermentationLogId'] ?? '',
        type: map['type'] ?? '',
        title: map['title'] ?? '',
        description: map['description'],
        timestamp: map['timestamp'] is Timestamp
            ? (map['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        stageId: map['stageId'],
        stageIndex: map['stageIndex'] as int?,
        metadata: map['metadata'] as Map<String, dynamic>?,
        userId: map['userId'],
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory TimelineEvent.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return TimelineEvent.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'fermentationLogId': fermentationLogId,
        'type': type,
        'title': title,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'stageId': stageId,
        'stageIndex': stageIndex,
        'metadata': metadata,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  TimelineEvent copyWith({
    String? fermentationLogId,
    String? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? stageId,
    int? stageIndex,
    Map<String, dynamic>? metadata,
    String? userId,
    DateTime? createdAt,
  }) => TimelineEvent(
        id: id,
        fermentationLogId: fermentationLogId ?? this.fermentationLogId,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
        stageId: stageId ?? this.stageId,
        stageIndex: stageIndex ?? this.stageIndex,
        metadata: metadata ?? this.metadata,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Validate timeline event
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate fermentation log ID
    results.add(ValidationUtils.validateRequiredString(fermentationLogId, 'Fermentation Log ID'));
    results.add(ValidationUtils.validateUid(fermentationLogId));

    // Validate type
    const validTypes = ['stage_start', 'stage_complete', 'stage_skip', 'stage_fail', 'note', 'photo', 'measurement'];
    if (!validTypes.contains(type)) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Invalid timeline event type'],
      ));
    }

    // Validate title
    results.add(ValidationUtils.validateRequiredString(title, 'Title'));
    results.add(ValidationUtils.validateStringLength(title, 'Title', minLength: 1, maxLength: 200));

    // Validate description (optional)
    if (description != null && description!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(description!, 'Description', maxLength: 1000));
    }

    // Validate timestamp
    final now = DateTime.now();
    results.add(ValidationUtils.validateDateRange(timestamp, 'Timestamp', maxDate: now));

    // Validate stage ID (optional)
    if (stageId != null && stageId!.isNotEmpty) {
      results.add(ValidationUtils.validateUid(stageId!));
    }

    // Validate stage index (optional)
    if (stageIndex != null) {
      results.add(ValidationUtils.validateNumberRange(stageIndex!, 'Stage Index', min: 0));
    }

    // Validate user ID (optional)
    if (userId != null && userId!.isNotEmpty) {
      results.add(ValidationUtils.validateUid(userId!));
    }

    // Validate created date
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created Date', maxDate: now));

    return ValidationResult.combine(results);
  }

  /// Check if timeline event is valid (convenience method)
  bool get isValid => validate().isValid;

  /// Get validation errors (convenience method)
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings (convenience method)
  List<String> get validationWarnings => validate().warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fermentationLogId == other.fermentationLogId &&
          type == other.type &&
          title == other.title &&
          description == other.description &&
          timestamp == other.timestamp &&
          stageId == other.stageId &&
          stageIndex == other.stageIndex &&
          _mapEquals(metadata, other.metadata) &&
          userId == other.userId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        fermentationLogId,
        type,
        title,
        description,
        timestamp,
        stageId,
        stageIndex,
        metadata,
        userId,
        createdAt,
      );

  static bool _mapEquals(Map? a, Map? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Represents the complete timeline of a fermentation process
class FermentationTimeline {
  final String id;
  final String fermentationLogId;
  final List<TimelineEvent> events;
  final List<StageCompletion> stageCompletions;
  final DateTime createdAt;
  final DateTime updatedAt;

  FermentationTimeline({
    required this.id,
    required this.fermentationLogId,
    required this.events,
    required this.stageCompletions,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String collectionPath = 'fermentation_timelines';
  static String docPath(String id) => 'fermentation_timelines/$id';

  factory FermentationTimeline.fromMap(String id, Map<String, dynamic> map) => FermentationTimeline(
        id: id,
        fermentationLogId: map['fermentationLogId'] ?? '',
        events: _parseEvents(map['events']),
        stageCompletions: _parseStageCompletions(map['stageCompletions']),
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory FermentationTimeline.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return FermentationTimeline.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'fermentationLogId': fermentationLogId,
        'events': events.map((e) => e.toMap()).toList(),
        'stageCompletions': stageCompletions.map((e) => e.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  FermentationTimeline copyWith({
    String? fermentationLogId,
    List<TimelineEvent>? events,
    List<StageCompletion>? stageCompletions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FermentationTimeline(
        id: id,
        fermentationLogId: fermentationLogId ?? this.fermentationLogId,
        events: events ?? this.events,
        stageCompletions: stageCompletions ?? this.stageCompletions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Validate fermentation timeline
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate fermentation log ID
    results.add(ValidationUtils.validateRequiredString(fermentationLogId, 'Fermentation Log ID'));
    results.add(ValidationUtils.validateUid(fermentationLogId));

    // Validate events
    for (int i = 0; i < events.length; i++) {
      final eventResult = events[i].validate();
      if (!eventResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: eventResult.errors.map((e) => 'Event ${i + 1}: $e').toList(),
        ));
      }
    }

    // Validate stage completions
    for (int i = 0; i < stageCompletions.length; i++) {
      final completionResult = stageCompletions[i].validate();
      if (!completionResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: completionResult.errors.map((e) => 'Stage Completion ${i + 1}: $e').toList(),
        ));
      }
    }

    // Validate dates
    final now = DateTime.now();
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created Date', maxDate: now));
    results.add(ValidationUtils.validateDateRange(updatedAt, 'Updated Date', maxDate: now));

    // Business logic validations
    if (updatedAt.isBefore(createdAt)) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Updated date cannot be before created date'],
      ));
    }

    return ValidationResult.combine(results);
  }

  /// Check if fermentation timeline is valid (convenience method)
  bool get isValid => validate().isValid;

  /// Get validation errors (convenience method)
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings (convenience method)
  List<String> get validationWarnings => validate().warnings;

  /// Get events sorted by timestamp
  List<TimelineEvent> get sortedEvents {
    final sorted = List<TimelineEvent>.from(events);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  /// Get stage completions sorted by stage index
  List<StageCompletion> get sortedStageCompletions {
    final sorted = List<StageCompletion>.from(stageCompletions);
    sorted.sort((a, b) => a.stageIndex.compareTo(b.stageIndex));
    return sorted;
  }

  /// Get completion rate (percentage of completed stages)
  double get completionRate {
    if (stageCompletions.isEmpty) return 0.0;
    final completed = stageCompletions.where((s) => s.status == StageCompletionStatus.completed).length;
    return (completed / stageCompletions.length) * 100;
  }

  /// Get total duration of completed stages
  Duration get totalStageDuration {
    Duration total = Duration.zero;
    for (final completion in stageCompletions) {
      if (completion.duration != null) {
        total += completion.duration!;
      }
    }
    return total;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FermentationTimeline &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fermentationLogId == other.fermentationLogId &&
          _listEquals(events, other.events) &&
          _listEquals(stageCompletions, other.stageCompletions) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        fermentationLogId,
        Object.hashAll(events),
        Object.hashAll(stageCompletions),
        createdAt,
        updatedAt,
      );

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<TimelineEvent> _parseEvents(dynamic eventsData) {
    try {
      if (eventsData is List) {
        return eventsData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return TimelineEvent.fromMap('temp_id', e);
                } else if (e is Map) {
                  return TimelineEvent.fromMap('temp_id', Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing timeline event: $e', e);
                return null;
              }
            })
            .where((event) => event != null)
            .cast<TimelineEvent>()
            .toList();
      }
      return const <TimelineEvent>[];
    } catch (e) {
      AppLogger.error('Error parsing timeline events list: $e', e);
      return const <TimelineEvent>[];
    }
  }

  static List<StageCompletion> _parseStageCompletions(dynamic completionsData) {
    try {
      if (completionsData is List) {
        return completionsData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return StageCompletion.fromMap('temp_id', e);
                } else if (e is Map) {
                  return StageCompletion.fromMap('temp_id', Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing stage completion: $e', e);
                return null;
              }
            })
            .where((completion) => completion != null)
            .cast<StageCompletion>()
            .toList();
      }
      return const <StageCompletion>[];
    } catch (e) {
      AppLogger.error('Error parsing stage completions list: $e', e);
      return const <StageCompletion>[];
    }
  }
}
