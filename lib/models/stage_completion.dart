import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation.dart';

/// Represents the completion status of a fermentation stage
enum StageCompletionStatus {
  pending,    // Not yet started
  inProgress, // Currently being worked on
  completed,  // Successfully completed
  skipped,    // Intentionally skipped
  failed,     // Failed to complete properly
}

/// Represents the actual completion of a fermentation stage
class StageCompletion {
  final String id;
  final String fermentationLogId;
  final int stageIndex; // Index in the stages list
  final int plannedDay; // Original planned day
  final String stageLabel;
  final String stageAction;
  final StageCompletionStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? actualAction; // What was actually done (may differ from planned)
  final String? notes; // User notes about the completion
  final List<String> photos; // Photos taken during this stage
  final Map<String, dynamic>? measurements; // Any measurements taken
  final String? completedBy; // User who completed the stage
  final DateTime createdAt;
  final DateTime updatedAt;

  const StageCompletion({
    required this.id,
    required this.fermentationLogId,
    required this.stageIndex,
    required this.plannedDay,
    required this.stageLabel,
    required this.stageAction,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.actualAction,
    this.notes,
    required this.photos,
    this.measurements,
    this.completedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String collectionPath = 'stage_completions';
  static String docPath(String id) => 'stage_completions/$id';
  static String fermentationScopedPath(String fermentationLogId) => 
      'fermentation_logs/$fermentationLogId/stage_completions';

  factory StageCompletion.fromMap(String id, Map<String, dynamic> map) => StageCompletion(
        id: id,
        fermentationLogId: map['fermentationLogId'] ?? '',
        stageIndex: (map['stageIndex'] ?? 0) as int,
        plannedDay: (map['plannedDay'] ?? 0) as int,
        stageLabel: map['stageLabel'] ?? '',
        stageAction: map['stageAction'] ?? '',
        status: _parseStatus(map['status']),
        startedAt: map['startedAt'] is Timestamp
            ? (map['startedAt'] as Timestamp).toDate()
            : null,
        completedAt: map['completedAt'] is Timestamp
            ? (map['completedAt'] as Timestamp).toDate()
            : null,
        actualAction: map['actualAction'],
        notes: map['notes'],
        photos: ValidationUtils.safeParseStringList(map['photos']),
        measurements: map['measurements'] as Map<String, dynamic>?,
        completedBy: map['completedBy'],
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory StageCompletion.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return StageCompletion.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'fermentationLogId': fermentationLogId,
        'stageIndex': stageIndex,
        'plannedDay': plannedDay,
        'stageLabel': stageLabel,
        'stageAction': stageAction,
        'status': status.name,
        'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'actualAction': actualAction,
        'notes': notes,
        'photos': photos,
        'measurements': measurements,
        'completedBy': completedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  StageCompletion copyWith({
    String? fermentationLogId,
    int? stageIndex,
    int? plannedDay,
    String? stageLabel,
    String? stageAction,
    StageCompletionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? actualAction,
    String? notes,
    List<String>? photos,
    Map<String, dynamic>? measurements,
    String? completedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StageCompletion(
        id: id,
        fermentationLogId: fermentationLogId ?? this.fermentationLogId,
        stageIndex: stageIndex ?? this.stageIndex,
        plannedDay: plannedDay ?? this.plannedDay,
        stageLabel: stageLabel ?? this.stageLabel,
        stageAction: stageAction ?? this.stageAction,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        actualAction: actualAction ?? this.actualAction,
        notes: notes ?? this.notes,
        photos: photos ?? this.photos,
        measurements: measurements ?? this.measurements,
        completedBy: completedBy ?? this.completedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Validate stage completion
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate fermentation log ID
    results.add(ValidationUtils.validateRequiredString(fermentationLogId, 'Fermentation Log ID'));
    results.add(ValidationUtils.validateUid(fermentationLogId));

    // Validate stage index
    results.add(ValidationUtils.validateNumberRange(stageIndex, 'Stage Index', min: 0));

    // Validate planned day
    results.add(ValidationUtils.validateNumberRange(plannedDay, 'Planned Day', min: 0, max: 365));

    // Validate stage label
    results.add(ValidationUtils.validateRequiredString(stageLabel, 'Stage Label'));
    results.add(ValidationUtils.validateStringLength(stageLabel, 'Stage Label', minLength: 1, maxLength: 100));

    // Validate stage action
    results.add(ValidationUtils.validateRequiredString(stageAction, 'Stage Action'));
    results.add(ValidationUtils.validateStringLength(stageAction, 'Stage Action', minLength: 1, maxLength: 500));

    // Validate status
    results.add(ValidationUtils.validateEnum(status, StageCompletionStatus.values, 'Status'));

    // Validate dates
    final now = DateTime.now();
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created Date', maxDate: now));
    results.add(ValidationUtils.validateDateRange(updatedAt, 'Updated Date', maxDate: now));

    if (startedAt != null) {
      results.add(ValidationUtils.validateDateRange(startedAt!, 'Started Date', maxDate: now));
    }

    if (completedAt != null) {
      results.add(ValidationUtils.validateDateRange(completedAt!, 'Completed Date', maxDate: now));
      
      // Business logic: completed date should not be before started date
      if (startedAt != null && completedAt!.isBefore(startedAt!)) {
        results.add(const ValidationResult(
          isValid: false,
          errors: ['Completed date cannot be before started date'],
        ));
      }
    }

    // Validate actual action (optional)
    if (actualAction != null && actualAction!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(actualAction!, 'Actual Action', minLength: 1, maxLength: 500));
    }

    // Validate notes (optional)
    if (notes != null && notes!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(notes!, 'Notes', maxLength: 1000));
    }

    // Validate photos
    results.add(ValidationUtils.validateListLength(photos, 'Photos', maxLength: 10));
    for (int i = 0; i < photos.length; i++) {
      final urlResult = ValidationUtils.validateUrl(photos[i]);
      if (!urlResult.isValid) {
        results.add(ValidationResult(
          isValid: false,
          errors: ['Photo ${i + 1}: Invalid URL format'],
        ));
      }
    }

    // Validate completed by (optional)
    if (completedBy != null && completedBy!.isNotEmpty) {
      results.add(ValidationUtils.validateUid(completedBy!));
    }

    // Business logic validations
    if (status == StageCompletionStatus.completed && completedAt == null) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Completed stages must have a completion date'],
      ));
    }

    if (status == StageCompletionStatus.inProgress && startedAt == null) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['In-progress stages must have a start date'],
      ));
    }

    return ValidationResult.combine(results);
  }

  /// Check if stage completion is valid (convenience method)
  bool get isValid => validate().isValid;

  /// Get validation errors (convenience method)
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings (convenience method)
  List<String> get validationWarnings => validate().warnings;

  /// Get duration of the stage (if completed)
  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  /// Get actual day when completed (relative to fermentation start)
  int? get actualDay {
    if (completedAt != null) {
      // This would need the fermentation start date to calculate
      // For now, return null - this will be calculated in the service layer
      return null;
    }
    return null;
  }

  /// Check if stage was completed on time
  bool? get wasOnTime {
    if (actualDay != null) {
      return actualDay! <= plannedDay;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageCompletion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fermentationLogId == other.fermentationLogId &&
          stageIndex == other.stageIndex &&
          plannedDay == other.plannedDay &&
          stageLabel == other.stageLabel &&
          stageAction == other.stageAction &&
          status == other.status &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          actualAction == other.actualAction &&
          notes == other.notes &&
          _listEquals(photos, other.photos) &&
          _mapEquals(measurements, other.measurements) &&
          completedBy == other.completedBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        fermentationLogId,
        stageIndex,
        plannedDay,
        stageLabel,
        stageAction,
        status,
        startedAt,
        completedAt,
        actualAction,
        notes,
        Object.hashAll(photos),
        measurements,
        completedBy,
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

  static bool _mapEquals(Map? a, Map? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static StageCompletionStatus _parseStatus(dynamic status) {
    if (status == null) return StageCompletionStatus.pending;
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'inprogress':
      case 'in_progress':
        return StageCompletionStatus.inProgress;
      case 'completed':
        return StageCompletionStatus.completed;
      case 'skipped':
        return StageCompletionStatus.skipped;
      case 'failed':
        return StageCompletionStatus.failed;
      default:
        return StageCompletionStatus.pending;
    }
  }
}
