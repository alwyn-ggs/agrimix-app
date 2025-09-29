# Stage Management & Timeline System

This document explains the comprehensive stage management and timeline tracking system implemented for fermentation processes in the Agrimix Flutter application.

## Overview

The stage management system provides:
- **Complete stage completion history tracking**
- **Advanced stage validation** (overlapping days, invalid sequences)
- **Flexible stage modification** after fermentation starts
- **Detailed timeline tracking** with actual completion times
- **Comprehensive insights** for learning from past experiences
- **Automated recommendations** for improving fermentation processes

## Components

### 1. Stage Completion Model (`lib/models/stage_completion.dart`)

#### Core Features:
- **Completion Status Tracking**: pending, inProgress, completed, skipped, failed
- **Actual vs Planned Actions**: Track what was actually done vs what was planned
- **Timing Data**: Start time, completion time, duration calculation
- **Rich Metadata**: Notes, photos, measurements, user attribution
- **Validation**: Comprehensive validation with business logic constraints

#### Usage Examples:

```dart
// Create a stage completion
final completion = StageCompletion(
  id: 'stage_id',
  fermentationLogId: 'fermentation_id',
  stageIndex: 0,
  plannedDay: 7,
  stageLabel: 'First Stir',
  stageAction: 'Stir the mixture gently',
  status: StageCompletionStatus.inProgress,
  startedAt: DateTime.now(),
  photos: const [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Check validation
if (!completion.isValid) {
  print('Validation errors: ${completion.validationErrors}');
}

// Get duration
final duration = completion.duration; // Duration between start and completion
final wasOnTime = completion.wasOnTime; // Whether completed on planned day
```

### 2. Timeline System (`lib/models/fermentation_timeline.dart`)

#### Core Features:
- **Timeline Events**: Track all activities during fermentation
- **Event Types**: stage_start, stage_complete, stage_skip, stage_fail, note, photo, measurement
- **Rich Metadata**: Support for measurements, photos, and custom data
- **Chronological Ordering**: Events sorted by timestamp
- **Completion Analytics**: Calculate completion rates and durations

#### Usage Examples:

```dart
// Create a timeline event
final event = TimelineEvent(
  id: 'event_id',
  fermentationLogId: 'fermentation_id',
  type: 'stage_complete',
  title: 'Completed: First Stir',
  description: 'Successfully stirred the mixture',
  timestamp: DateTime.now(),
  stageId: 'stage_id',
  stageIndex: 0,
  metadata: {'duration': 15, 'wasOnTime': true},
  userId: 'user_id',
  createdAt: DateTime.now(),
);

// Get fermentation timeline
final timeline = FermentationTimeline(
  id: 'timeline_id',
  fermentationLogId: 'fermentation_id',
  events: [event],
  stageCompletions: [completion],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Get analytics
final completionRate = timeline.completionRate; // Percentage completed
final totalDuration = timeline.totalStageDuration; // Total time spent
final sortedEvents = timeline.sortedEvents; // Events in chronological order
```

### 3. Stage Management Service (`lib/services/stage_management_service.dart`)

#### Core Features:
- **Stage Lifecycle Management**: Start, complete, skip, fail stages
- **Timeline Integration**: Automatic timeline event creation
- **Validation**: Stage sequence validation with business rules
- **Fermentation Completion**: Automatic detection when all stages are done
- **Rich Data Support**: Notes, photos, measurements for each stage

#### Usage Examples:

```dart
final service = StageManagementService();

// Start a stage
final stageCompletion = await service.startStage(
  fermentationLogId: 'fermentation_id',
  stageIndex: 0,
  stageLabel: 'First Stir',
  stageAction: 'Stir the mixture gently',
  plannedDay: 7,
  userId: 'user_id',
);

// Complete a stage
final completedStage = await service.completeStage(
  stageId: stageCompletion.id,
  actualAction: 'Stirred for 5 minutes clockwise',
  notes: 'Mixture looks good, no issues',
  photos: ['photo_url_1', 'photo_url_2'],
  measurements: {'temperature': 25.5, 'ph': 6.8},
  userId: 'user_id',
);

// Skip a stage
await service.skipStage(
  stageId: stageCompletion.id,
  reason: 'Weather conditions not suitable',
  userId: 'user_id',
);

// Add timeline notes
await service.addTimelineNote(
  fermentationLogId: 'fermentation_id',
  title: 'Weather Update',
  description: 'Heavy rain expected, moved fermentation indoors',
  userId: 'user_id',
);

// Add measurements
await service.addTimelineMeasurement(
  fermentationLogId: 'fermentation_id',
  measurementType: 'temperature',
  value: 24.5,
  unit: '°C',
  description: 'Room temperature check',
  userId: 'user_id',
);

// Validate stage sequence
final validation = service.validateStageSequence(stages);
if (!validation.isValid) {
  print('Stage sequence issues: ${validation.errors}');
}
```

### 4. Insights Service (`lib/services/fermentation_insights_service.dart`)

#### Core Features:
- **User Insights**: Personal fermentation performance analytics
- **Method Insights**: Compare FFJ vs FPJ performance
- **Recipe Insights**: Analyze recipe-specific success rates
- **Stage Performance**: Identify problematic stages
- **Smart Recommendations**: AI-driven suggestions for improvement

#### Usage Examples:

```dart
final insightsService = FermentationInsightsService();

// Get user insights
final userInsights = await insightsService.getUserInsights('user_id');
print('Total fermentations: ${userInsights.totalFermentations}');
print('Completion rate: ${userInsights.averageCompletionRate}%');
print('Timing accuracy: ${userInsights.averageTimingAccuracy}%');

// Get method insights
final methodInsights = await insightsService.getMethodInsights(FermentationMethod.ffj);
print('FFJ success rate: ${methodInsights.successRate}%');
print('Average duration: ${methodInsights.averageDuration.inDays} days');

// Get stage performance insights
final stageInsights = await insightsService.getStagePerformanceInsights(userId: 'user_id');
for (final stage in stageInsights.problematicStages) {
  print('${stage.stageLabel}: ${stage.failureRate}% failure rate');
}

// Get recommendations
final recommendations = await insightsService.getRecommendations('user_id');
for (final recommendation in recommendations) {
  print('${recommendation.priority.name.toUpperCase()}: ${recommendation.title}');
  print('Action: ${recommendation.action}');
}
```

## Key Features

### 1. Stage Completion History Tracking

```dart
// Get all stage completions for a fermentation
final completions = await service.getStageCompletions('fermentation_id');

// Analyze completion patterns
final completed = completions.where((c) => c.status == StageCompletionStatus.completed);
final skipped = completions.where((c) => c.status == StageCompletionStatus.skipped);
final failed = completions.where((c) => c.status == StageCompletionStatus.failed);

print('Completed: ${completed.length}, Skipped: ${skipped.length}, Failed: ${failed.length}');
```

### 2. Stage Validation

```dart
// Validate stage sequence before starting fermentation
final stages = [
  FermentationStage(day: 1, label: 'Initial Mix', action: 'Mix ingredients'),
  FermentationStage(day: 3, label: 'First Stir', action: 'Stir gently'),
  FermentationStage(day: 7, label: 'Second Stir', action: 'Stir again'),
];

final validation = service.validateStageSequence(stages);
if (!validation.isValid) {
  // Handle validation errors
  for (final error in validation.errors) {
    print('Error: $error');
  }
}
```

### 3. Timeline Tracking

```dart
// Get complete timeline
final timeline = await service.getFermentationTimeline('fermentation_id');

// Get events by type
final stageEvents = timeline.events.where((e) => e.type.startsWith('stage_'));
final notes = timeline.events.where((e) => e.type == 'note');
final photos = timeline.events.where((e) => e.type == 'photo');
final measurements = timeline.events.where((e) => e.type == 'measurement');

// Calculate insights
final completionRate = timeline.completionRate;
final totalDuration = timeline.totalStageDuration;
```

### 4. Insights and Analytics

```dart
// Get comprehensive user insights
final insights = await insightsService.getUserInsights('user_id');

// Method performance comparison
for (final entry in insights.methodPerformance.entries) {
  final method = entry.key;
  final performance = entry.value;
  print('${method.name}: ${performance.completionRate}% completion rate');
}

// Get actionable recommendations
final recommendations = await insightsService.getRecommendations('user_id');
for (final rec in recommendations) {
  if (rec.priority == Priority.high) {
    print('HIGH PRIORITY: ${rec.title}');
    print('Action: ${rec.action}');
  }
}
```

## Data Models

### StageCompletion Fields:
- `id`: Unique identifier
- `fermentationLogId`: Reference to fermentation log
- `stageIndex`: Position in stages list
- `plannedDay`: Originally planned day
- `stageLabel`: Human-readable stage name
- `stageAction`: Planned action description
- `status`: Current completion status
- `startedAt`: When stage was started
- `completedAt`: When stage was completed
- `actualAction`: What was actually done
- `notes`: User notes
- `photos`: Photo URLs
- `measurements`: Key-value measurements
- `completedBy`: User who completed the stage

### TimelineEvent Fields:
- `id`: Unique identifier
- `fermentationLogId`: Reference to fermentation log
- `type`: Event type (stage_start, stage_complete, etc.)
- `title`: Event title
- `description`: Event description
- `timestamp`: When event occurred
- `stageId`: Reference to stage completion (if applicable)
- `stageIndex`: Stage index (if applicable)
- `metadata`: Additional event data
- `userId`: User who triggered the event

## Business Logic

### Stage Validation Rules:
1. **No Overlapping Days**: Each stage must have a unique day
2. **Sequential Order**: Days should generally be in ascending order
3. **Minimum Gap**: Stages should be at least 1 day apart
4. **Maximum Gap**: Warn if stages are more than 30 days apart
5. **Valid Status Transitions**: pending → inProgress → completed/skipped/failed

### Timeline Event Types:
- `stage_start`: Stage marked as in progress
- `stage_complete`: Stage successfully completed
- `stage_skip`: Stage intentionally skipped
- `stage_fail`: Stage failed to complete
- `note`: General timeline note
- `photo`: Photo added to timeline
- `measurement`: Measurement recorded

### Completion Detection:
- Fermentation is marked as "done" when all stages are completed, skipped, or failed
- Timeline event is automatically created when fermentation completes
- Current stage index is updated as stages progress

## Integration with Existing System

### FermentationLog Integration:
```dart
// Initialize stages when creating fermentation
final fermentation = FermentationLog(/* ... */);
await service.initializeStages(
  fermentationLogId: fermentation.id,
  stages: fermentation.stages,
  userId: fermentation.ownerUid,
);

// Update current stage as fermentation progresses
await service.startStage(/* ... */); // Automatically updates currentStage
```

### Validation Integration:
```dart
// Use existing validation framework
final validation = stageCompletion.validate();
if (!validation.isValid) {
  // Handle validation errors using existing error handling
}
```

## Performance Considerations

### Database Queries:
- Stage completions are queried by fermentation ID with proper indexing
- Timeline events are ordered by timestamp for chronological display
- Batch operations are used for multiple stage initializations

### Caching:
- Timeline data can be cached for frequently accessed fermentations
- Insights can be calculated periodically and cached
- Stage completions are fetched on-demand

### Scalability:
- Timeline events are stored in separate collection for better performance
- Stage completions use subcollections for large fermentations
- Pagination is supported for large datasets

## Error Handling

### Validation Errors:
```dart
try {
  final completion = await service.completeStage(/* ... */);
} catch (e) {
  if (e is ValidationException) {
    // Handle validation errors
    print('Validation failed: ${e.errors}');
  } else {
    // Handle other errors
    print('Unexpected error: $e');
  }
}
```

### Network Errors:
```dart
try {
  final timeline = await service.getFermentationTimeline('id');
} catch (e) {
  // Handle network or database errors
  AppLogger.error('Failed to get timeline: $e');
  // Show user-friendly error message
}
```

## Testing

### Unit Tests:
```dart
// Test stage validation
test('should validate stage sequence', () {
  final stages = [/* test stages */];
  final validation = service.validateStageSequence(stages);
  expect(validation.isValid, true);
});

// Test stage completion
test('should complete stage successfully', () async {
  final completion = await service.completeStage(/* ... */);
  expect(completion.status, StageCompletionStatus.completed);
});
```

### Integration Tests:
```dart
// Test full fermentation lifecycle
test('should track complete fermentation timeline', () async {
  // Start fermentation
  // Complete stages
  // Verify timeline
  // Check insights
});
```

This stage management and timeline system provides comprehensive tracking, validation, and insights for fermentation processes, enabling users to learn from past experiences and improve their fermentation practices.
