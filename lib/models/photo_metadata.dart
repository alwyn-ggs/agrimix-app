import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation.dart';

/// Represents metadata for a fermentation photo
class PhotoMetadata {
  final String id;
  final String fermentationLogId;
  final String? stageId;
  final String stageLabel;
  final String? description;
  final DateTime timestamp;
  final String originalUrl;
  final String? compressedUrl;
  final String? thumbnailUrl;
  final int originalSizeBytes;
  final int? compressedSizeBytes;
  final PhotoQuality quality;
  final PhotoStatus status;
  final Map<String, dynamic>? exifData;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhotoMetadata({
    required this.id,
    required this.fermentationLogId,
    this.stageId,
    required this.stageLabel,
    this.description,
    required this.timestamp,
    required this.originalUrl,
    this.compressedUrl,
    this.thumbnailUrl,
    required this.originalSizeBytes,
    this.compressedSizeBytes,
    required this.quality,
    required this.status,
    this.exifData,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String collectionPath = 'photo_metadata';
  static String docPath(String id) => 'photo_metadata/$id';

  factory PhotoMetadata.fromMap(String id, Map<String, dynamic> map) => PhotoMetadata(
        id: id,
        fermentationLogId: map['fermentationLogId'] ?? '',
        stageId: map['stageId'],
        stageLabel: map['stageLabel'] ?? '',
        description: map['description'],
        timestamp: map['timestamp'] is Timestamp
            ? (map['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        originalUrl: map['originalUrl'] ?? '',
        compressedUrl: map['compressedUrl'],
        thumbnailUrl: map['thumbnailUrl'],
        originalSizeBytes: (map['originalSizeBytes'] ?? 0) as int,
        compressedSizeBytes: map['compressedSizeBytes'] as int?,
        quality: PhotoQuality.values.firstWhere(
          (e) => e.name == map['quality'],
          orElse: () => PhotoQuality.medium,
        ),
        status: PhotoStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => PhotoStatus.uploading,
        ),
        exifData: map['exifData'] as Map<String, dynamic>?,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory PhotoMetadata.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return PhotoMetadata.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'fermentationLogId': fermentationLogId,
        'stageId': stageId,
        'stageLabel': stageLabel,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'originalUrl': originalUrl,
        'compressedUrl': compressedUrl,
        'thumbnailUrl': thumbnailUrl,
        'originalSizeBytes': originalSizeBytes,
        'compressedSizeBytes': compressedSizeBytes,
        'quality': quality.name,
        'status': status.name,
        'exifData': exifData,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  PhotoMetadata copyWith({
    String? fermentationLogId,
    String? stageId,
    String? stageLabel,
    String? description,
    DateTime? timestamp,
    String? originalUrl,
    String? compressedUrl,
    String? thumbnailUrl,
    int? originalSizeBytes,
    int? compressedSizeBytes,
    PhotoQuality? quality,
    PhotoStatus? status,
    Map<String, dynamic>? exifData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PhotoMetadata(
        id: id,
        fermentationLogId: fermentationLogId ?? this.fermentationLogId,
        stageId: stageId ?? this.stageId,
        stageLabel: stageLabel ?? this.stageLabel,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
        originalUrl: originalUrl ?? this.originalUrl,
        compressedUrl: compressedUrl ?? this.compressedUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
        compressedSizeBytes: compressedSizeBytes ?? this.compressedSizeBytes,
        quality: quality ?? this.quality,
        status: status ?? this.status,
        exifData: exifData ?? this.exifData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fermentationLogId == other.fermentationLogId &&
          stageId == other.stageId &&
          stageLabel == other.stageLabel &&
          description == other.description &&
          timestamp == other.timestamp &&
          originalUrl == other.originalUrl &&
          compressedUrl == other.compressedUrl &&
          thumbnailUrl == other.thumbnailUrl &&
          originalSizeBytes == other.originalSizeBytes &&
          compressedSizeBytes == other.compressedSizeBytes &&
          quality == other.quality &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        fermentationLogId,
        stageId,
        stageLabel,
        description,
        timestamp,
        originalUrl,
        compressedUrl,
        thumbnailUrl,
        originalSizeBytes,
        compressedSizeBytes,
        quality,
        status,
      );

  /// Validate photo metadata
  ValidationResult validate() {
    final results = <ValidationResult>[];

    // Validate ID
    results.add(ValidationUtils.validateRequiredString(id, 'ID'));
    results.add(ValidationUtils.validateUid(id));

    // Validate fermentation log ID
    results.add(ValidationUtils.validateRequiredString(fermentationLogId, 'Fermentation Log ID'));
    results.add(ValidationUtils.validateUid(fermentationLogId));

    // Validate stage label
    results.add(ValidationUtils.validateRequiredString(stageLabel, 'Stage Label'));
    results.add(ValidationUtils.validateStringLength(stageLabel, 'Stage Label', minLength: 1, maxLength: 100));

    // Validate description (optional)
    if (description != null && description!.isNotEmpty) {
      results.add(ValidationUtils.validateStringLength(description!, 'Description', maxLength: 500));
    }

    // Validate URLs
    results.add(ValidationUtils.validateRequiredString(originalUrl, 'Original URL'));
    results.add(ValidationUtils.validateUrl(originalUrl));

    if (compressedUrl != null && compressedUrl!.isNotEmpty) {
      results.add(ValidationUtils.validateUrl(compressedUrl!));
    }

    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      results.add(ValidationUtils.validateUrl(thumbnailUrl!));
    }

    // Validate file sizes
    results.add(ValidationUtils.validatePositiveNumber(originalSizeBytes.toDouble(), 'Original Size'));
    results.add(ValidationUtils.validateNumberRange(originalSizeBytes.toDouble(), 'Original Size', max: 50 * 1024 * 1024)); // 50MB max

    if (compressedSizeBytes != null) {
      results.add(ValidationUtils.validatePositiveNumber(compressedSizeBytes!.toDouble(), 'Compressed Size'));
      if (compressedSizeBytes! > originalSizeBytes) {
        results.add(const ValidationResult(
          isValid: false,
          errors: ['Compressed size cannot be larger than original size'],
        ));
      }
    }

    // Validate timestamps
    final now = DateTime.now();
    results.add(ValidationUtils.validateDateRange(timestamp, 'Timestamp', maxDate: now));
    results.add(ValidationUtils.validateDateRange(createdAt, 'Created At', maxDate: now));
    results.add(ValidationUtils.validateDateRange(updatedAt, 'Updated At', maxDate: now));

    // Business logic validations
    if (status == PhotoStatus.processed && compressedUrl == null) {
      results.add(const ValidationResult(
        isValid: false,
        errors: ['Processed photos must have a compressed URL'],
      ));
    }

    if (status == PhotoStatus.failed && originalSizeBytes > 10 * 1024 * 1024) { // 10MB
      results.add(const ValidationResult(
        isValid: false,
        warnings: ['Large photos that failed processing may need manual review'],
      ));
    }

    return ValidationResult.combine(results);
  }

  /// Check if photo metadata is valid
  bool get isValid => validate().isValid;

  /// Get validation errors
  List<String> get validationErrors => validate().errors;

  /// Get validation warnings
  List<String> get validationWarnings => validate().warnings;

  /// Get display URL (prefer compressed, fallback to original)
  String get displayUrl => compressedUrl ?? originalUrl;

  /// Get thumbnail URL (prefer thumbnail, fallback to compressed, then original)
  String get displayThumbnailUrl => thumbnailUrl ?? compressedUrl ?? originalUrl;

  /// Calculate compression ratio
  double get compressionRatio {
    if (compressedSizeBytes == null) return 1.0;
    return originalSizeBytes / compressedSizeBytes!;
  }

  /// Check if photo is optimized
  bool get isOptimized => compressedUrl != null && compressionRatio > 1.2;

  /// Get human-readable file size
  String get originalSizeFormatted => _formatBytes(originalSizeBytes);
  String get compressedSizeFormatted => compressedSizeBytes != null ? _formatBytes(compressedSizeBytes!) : 'N/A';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Photo quality levels
enum PhotoQuality {
  low,      // For thumbnails
  medium,   // For general use
  high,     // For detailed viewing
  original, // Uncompressed
}

/// Photo processing status
enum PhotoStatus {
  uploading,    // Being uploaded to storage
  processing,   // Being compressed/optimized
  processed,    // Successfully processed
  failed,       // Processing failed
  synced,       // Synced to backup
}

/// Photo organization by stage
class StagePhotoGroup {
  final String stageLabel;
  final List<PhotoMetadata> photos;
  final DateTime? firstPhotoDate;
  final DateTime? lastPhotoDate;

  const StagePhotoGroup({
    required this.stageLabel,
    required this.photos,
    this.firstPhotoDate,
    this.lastPhotoDate,
  });

  factory StagePhotoGroup.fromPhotos(List<PhotoMetadata> photos) {
    if (photos.isEmpty) {
      return const StagePhotoGroup(stageLabel: '', photos: []);
    }

    final stageLabel = photos.first.stageLabel;
    final sortedPhotos = List<PhotoMetadata>.from(photos)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return StagePhotoGroup(
      stageLabel: stageLabel,
      photos: sortedPhotos,
      firstPhotoDate: sortedPhotos.first.timestamp,
      lastPhotoDate: sortedPhotos.last.timestamp,
    );
  }

  int get photoCount => photos.length;
  int get totalSizeBytes => photos.fold(0, (total, photo) => total + photo.originalSizeBytes);
  String get totalSizeFormatted => PhotoMetadata._formatBytes(totalSizeBytes);

  /// Get photos by quality
  List<PhotoMetadata> getPhotosByQuality(PhotoQuality quality) =>
      photos.where((photo) => photo.quality == quality).toList();

  /// Get failed photos
  List<PhotoMetadata> get failedPhotos =>
      photos.where((photo) => photo.status == PhotoStatus.failed).toList();

  /// Get processed photos
  List<PhotoMetadata> get processedPhotos =>
      photos.where((photo) => photo.status == PhotoStatus.processed).toList();
}
