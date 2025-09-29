# Data Model Validation & Integrity System

This document explains the comprehensive validation and data integrity system implemented for the Agrimix Flutter application.

## Overview

The validation system provides:
- **Comprehensive data validation** for all models
- **Consistent error handling** in parsing methods
- **Data integrity constraints** and validation rules
- **Versioning support** for fermentation logs and other models
- **Data migration methods** for handling version differences
- **Automated data integrity checking** and repair

## Components

### 1. Validation Framework (`lib/utils/validation.dart`)

#### Core Classes:
- `ValidationResult`: Holds validation results with errors and warnings
- `ValidationUtils`: Static utility methods for common validations
- `ModelVersion`: Handles model versioning and compatibility
- `ModelValidator<T>`: Base class for model validators

#### Key Features:
- **Required field validation**
- **String length validation**
- **Email format validation**
- **Number range validation**
- **Date range validation**
- **URL format validation**
- **UID format validation**
- **Enum value validation**
- **List length validation**

### 2. Model Factory (`lib/utils/model_factory.dart`)

#### Features:
- **Safe model creation** with error handling
- **Automatic data migration** for version compatibility
- **Strict validation mode** for production use
- **Batch model creation** with error recovery
- **Custom exceptions** for different error types

#### Usage Examples:

```dart
// Basic model creation with validation
final log = ModelFactory.createFermentationLog(
  'log_id',
  data,
  strictValidation: true,
  enableMigration: true,
);

// Safe parsing from DocumentSnapshot
final user = ModelFactory.safeParseFromSnapshot(
  snapshot,
  (id, data) => ModelFactory.createUser(id, data),
  strictValidation: false,
);

// Batch creation with error handling
final posts = ModelFactory.batchCreate(
  dataList,
  (id, data) => ModelFactory.createPost(id, data),
  continueOnError: true,
);
```

### 3. Data Integrity Service (`lib/services/data_integrity_service.dart`)

#### Features:
- **Collection-wide validation**
- **Referential integrity checking**
- **Data consistency validation**
- **Automated issue fixing**
- **Comprehensive reporting**

#### Usage Examples:

```dart
// Validate a single collection
final report = await DataIntegrityService().validateCollection(
  'fermentation_logs',
  limit: 100,
  fixIssues: true,
);

// Run comprehensive check on all collections
final comprehensiveReport = await DataIntegrityService().runComprehensiveCheck(
  fixIssues: false,
  limitPerCollection: 50,
);

// Check specific document
final issues = await DataIntegrityService()._validateDocument(
  'recipes',
  'recipe_id',
  data,
);
```

## Model Validation

### FermentationLog Validation

```dart
final log = FermentationLog.fromMap(id, data);

// Check if valid
if (log.isValid) {
  // Use the log
} else {
  // Handle validation errors
  final errors = log.validationErrors;
  final warnings = log.validationWarnings;
}

// Get detailed validation result
final validation = log.validate();
if (!validation.isValid) {
  print('Errors: ${validation.errors}');
  print('Warnings: ${validation.warnings}');
}
```

### Recipe Validation

```dart
final recipe = Recipe.fromMap(id, data);

// Validate with enhanced factory
final validatedRecipe = Recipe.fromMapValidated(id, data);

// Check business logic constraints
if (!recipe.isValid) {
  // Handle validation errors
  for (final error in recipe.validationErrors) {
    print('Recipe error: $error');
  }
}
```

### User Validation

```dart
final user = AppUser.fromMap(id, data);

// Validate email format, role, etc.
if (!user.isValid) {
  // Handle validation errors
  print('User validation failed: ${user.validationErrors}');
}
```

## Data Migration

### Version Handling

```dart
// Create model with migration
final log = FermentationLog.fromMapWithMigration(id, data);

// Check version compatibility
final version = ModelVersion.fromString('1.0.0');
final currentVersion = ModelVersion(1, 1, 0);
if (version.isCompatibleWith(currentVersion)) {
  // Versions are compatible
}
```

### Migration Examples

```dart
// Automatic migration in ModelFactory
final log = ModelFactory.createFermentationLog(
  id,
  data,
  enableMigration: true, // Automatically applies migrations
);

// Manual migration
final migratedData = ModelFactory._applyMigration(data, 'fermentation_log');
```

## Error Handling

### Custom Exceptions

```dart
try {
  final model = ModelFactory.createFermentationLog(id, data, strictValidation: true);
} on ModelValidationException catch (e) {
  print('Validation failed: ${e.message}');
  print('Errors: ${e.errors}');
} on ModelCreationException catch (e) {
  print('Creation failed: ${e.message}');
  print('Original error: ${e.originalError}');
} on ModelMigrationException catch (e) {
  print('Migration failed: ${e.message}');
  print('From: ${e.fromVersion} to ${e.toVersion}');
}
```

### Safe Operations

```dart
// Safe parsing that returns null on error
final user = ModelFactory.safeParseFromSnapshot(
  snapshot,
  (id, data) => ModelFactory.createUser(id, data),
);

if (user != null) {
  // User was successfully created
} else {
  // Handle parsing error
}
```

## Data Integrity Checking

### Collection Validation

```dart
final service = DataIntegrityService();

// Validate single collection
final report = await service.validateCollection('recipes');
print('Valid documents: ${report.validCount}');
print('Issues found: ${report.issueCount}');
print('Critical issues: ${report.criticalIssueCount}');

// Fix issues automatically
final fixedReport = await service.validateCollection(
  'recipes',
  fixIssues: true,
);
```

### Comprehensive Checking

```dart
// Check all collections
final comprehensiveReport = await service.runComprehensiveCheck(
  fixIssues: true,
  limitPerCollection: 100,
);

print('Total collections: ${comprehensiveReport.totalCollections}');
print('Total documents: ${comprehensiveReport.totalDocuments}');
print('Valid documents: ${comprehensiveReport.totalValidDocuments}');
print('Total issues: ${comprehensiveReport.totalIssues}');
print('Critical issues: ${comprehensiveReport.totalCriticalIssues}');
```

## Best Practices

### 1. Use Strict Validation in Production

```dart
// Production code
final model = ModelFactory.createFermentationLog(
  id,
  data,
  strictValidation: true, // Always validate in production
  enableMigration: true,
);
```

### 2. Handle Validation Errors Gracefully

```dart
try {
  final model = ModelFactory.createFermentationLog(id, data, strictValidation: true);
  // Use model
} on ModelValidationException catch (e) {
  // Log error and show user-friendly message
  AppLogger.error('Validation failed: ${e.message}');
  showErrorDialog('Invalid data. Please check your input.');
}
```

### 3. Regular Data Integrity Checks

```dart
// Run integrity checks periodically
void runPeriodicIntegrityCheck() async {
  final report = await DataIntegrityService().runComprehensiveCheck(
    fixIssues: true,
    limitPerCollection: 1000,
  );
  
  if (report.totalCriticalIssues > 0) {
    // Alert administrators
    notifyAdmins('Critical data integrity issues found');
  }
}
```

### 4. Version Migration Strategy

```dart
// Always enable migration for backward compatibility
final model = ModelFactory.createModel(
  id,
  data,
  enableMigration: true, // Handle version differences
);
```

## Validation Rules Summary

### FermentationLog
- Title: 1-200 characters
- Ingredients: 1-50 items, each with valid name, amount, unit
- Stages: 1-100 items, each with valid day, label, action
- Start date: Not in future, within 1 year
- Current stage: Within valid range
- Photos: Max 20 URLs with valid format

### Recipe
- Name: 1-200 characters
- Description: 1-2000 characters
- Ingredients: 1-50 items with unique IDs
- Steps: 1-50 items with unique orders
- Rating: 0-5 range
- Image URLs: Max 10 with valid format

### User
- Name: 1-100 characters
- Email: Valid email format
- Role: 'farmer' or 'admin'
- FCM tokens: Max 10

### Post
- Title: 1-200 characters
- Body: 1-5000 characters
- Images: Max 10 URLs
- Tags: Max 20, each 1-50 characters
- Likes: Non-negative integer

### Comment
- Text: 1-1000 characters
- Author name: 1-100 characters (optional)
- Updated date: Not before created date

### Rating
- Stars: 1-5 range
- Comment: 1-1000 characters (optional)

### Announcement
- Title: 1-200 characters
- Body: 1-5000 characters
- Crop targets: Max 20, each 1-100 characters

### Violation
- Reason: 1-1000 characters
- Action reason: 1-1000 characters (optional)
- Ban expiration: Future date (if ban action)
- Resolved date: Not before created date

### Ingredient
- Name: 1-100 characters
- Category: 1-50 characters
- Description: 1-1000 characters (optional)
- Recommended crops: Max 50, each 1-100 characters
- Precautions: Max 20, each 1-500 characters

## Migration Guide

### From Old Models to New Validated Models

1. **Replace direct fromMap calls**:
   ```dart
   // Old
   final log = FermentationLog.fromMap(id, data);
   
   // New
   final log = ModelFactory.createFermentationLog(id, data);
   ```

2. **Add validation checks**:
   ```dart
   // Old
   final recipe = Recipe.fromMap(id, data);
   // Use recipe directly
   
   // New
   final recipe = ModelFactory.createRecipe(id, data, strictValidation: true);
   if (!recipe.isValid) {
     // Handle validation errors
   }
   ```

3. **Use enhanced toMap methods**:
   ```dart
   // Old
   final map = recipe.toMap();
   
   // New
   final map = recipe.toMapWithVersion(); // Includes version info
   ```

4. **Implement data integrity checks**:
   ```dart
   // Add to your app initialization
   void initializeDataIntegrity() async {
     final report = await DataIntegrityService().runComprehensiveCheck();
     if (report.totalCriticalIssues > 0) {
       // Handle critical issues
     }
   }
   ```

This validation and integrity system ensures data quality, prevents corruption, and provides a robust foundation for future feature development.
