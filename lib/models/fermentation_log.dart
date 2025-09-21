import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

enum FermentationStatus { active, done, cancelled }
enum FermentationMethod { FFJ, FPJ }

class FermentationStage {
  final int day;
  final String label;
  final String action;

  const FermentationStage({
    required this.day,
    required this.label,
    required this.action,
  });

  factory FermentationStage.fromMap(Map<String, dynamic> map) => FermentationStage(
        day: (map['day'] ?? 0) as int,
        label: map['label'] ?? '',
        action: map['action'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'label': label,
        'action': action,
      };
}

class FermentationIngredient {
  final String name;
  final double amount;
  final String unit;

  const FermentationIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory FermentationIngredient.fromMap(Map<String, dynamic> map) => FermentationIngredient(
        name: map['name'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'unit': unit,
      };
}

class FermentationLog {
  final String id;
  final String ownerUid;
  final String? recipeId;
  final String title;
  final FermentationMethod method;
  final List<FermentationIngredient> ingredients;
  final DateTime startAt;
  final List<FermentationStage> stages;
  final int currentStage;
  final FermentationStatus status;
  final String? notes;
  final List<String> photos;
  final bool alertsEnabled;
  final DateTime createdAt;

  const FermentationLog({
    required this.id,
    required this.ownerUid,
    this.recipeId,
    required this.title,
    required this.method,
    required this.ingredients,
    required this.startAt,
    required this.stages,
    required this.currentStage,
    required this.status,
    this.notes,
    required this.photos,
    required this.alertsEnabled,
    required this.createdAt,
  });

  static const String collectionPath = 'fermentation_logs';
  static String docPath(String id) => 'fermentation_logs/$id';

  factory FermentationLog.fromMap(String id, Map<String, dynamic> map) => FermentationLog(
        id: id,
        ownerUid: map['ownerUid'] ?? '',
        recipeId: map['recipeId'],
        title: map['title'] ?? '',
        method: (map['method'] == 'FPJ') ? FermentationMethod.FPJ : FermentationMethod.FFJ,
        ingredients: _parseIngredients(map['ingredients']),
        startAt: map['startAt'] is Timestamp
            ? (map['startAt'] as Timestamp).toDate()
            : DateTime.now(),
        stages: _parseStages(map['stages']),
        currentStage: (map['currentStage'] ?? 0) as int,
        status: map['status'] == 'done'
            ? FermentationStatus.done
            : map['status'] == 'cancelled'
                ? FermentationStatus.cancelled
                : FermentationStatus.active,
        notes: map['notes'],
        photos: _parsePhotos(map['photos']),
        alertsEnabled: (map['alertsEnabled'] ?? true) as bool,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory FermentationLog.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return FermentationLog.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'recipeId': recipeId,
        'title': title,
        'method': method == FermentationMethod.FPJ ? 'FPJ' : 'FFJ',
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'startAt': Timestamp.fromDate(startAt),
        'stages': stages.map((e) => e.toMap()).toList(),
        'currentStage': currentStage,
        'status': status == FermentationStatus.done
            ? 'done'
            : status == FermentationStatus.cancelled
                ? 'cancelled'
                : 'active',
        'notes': notes,
        'photos': photos,
        'alertsEnabled': alertsEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FermentationLog copyWith({
    String? ownerUid,
    String? recipeId,
    String? title,
    FermentationMethod? method,
    List<FermentationIngredient>? ingredients,
    DateTime? startAt,
    List<FermentationStage>? stages,
    int? currentStage,
    FermentationStatus? status,
    String? notes,
    List<String>? photos,
    bool? alertsEnabled,
    DateTime? createdAt,
  }) => FermentationLog(
        id: id,
        ownerUid: ownerUid ?? this.ownerUid,
        recipeId: recipeId ?? this.recipeId,
        title: title ?? this.title,
        method: method ?? this.method,
        ingredients: ingredients ?? this.ingredients,
        startAt: startAt ?? this.startAt,
        stages: stages ?? this.stages,
        currentStage: currentStage ?? this.currentStage,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        photos: photos ?? this.photos,
        alertsEnabled: alertsEnabled ?? this.alertsEnabled,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FermentationLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerUid == other.ownerUid &&
          recipeId == other.recipeId &&
          title == other.title &&
          method == other.method &&
          _listEquals(ingredients, other.ingredients) &&
          startAt == other.startAt &&
          _listEquals(stages, other.stages) &&
          currentStage == other.currentStage &&
          status == other.status &&
          notes == other.notes &&
          _listEquals(photos, other.photos) &&
          alertsEnabled == other.alertsEnabled &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        ownerUid,
        recipeId,
        title,
        method,
        Object.hashAll(ingredients.map((e) => Object.hash(e.name, e.amount, e.unit))),
        startAt,
        Object.hashAll(stages.map((e) => Object.hash(e.day, e.label, e.action))),
        currentStage,
        status,
        notes,
        Object.hashAll(photos),
        alertsEnabled,
        createdAt,
      );

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<FermentationIngredient> _parseIngredients(dynamic ingredientsData) {
    try {
      if (ingredientsData is List) {
        return ingredientsData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return FermentationIngredient.fromMap(e);
                } else if (e is Map) {
                  return FermentationIngredient.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing ingredient: $e', e);
                return null;
              }
            })
            .where((ingredient) => ingredient != null)
            .cast<FermentationIngredient>()
            .toList();
      }
      return const <FermentationIngredient>[];
    } catch (e) {
      AppLogger.error('Error parsing ingredients list: $e', e);
      return const <FermentationIngredient>[];
    }
  }

  static List<FermentationStage> _parseStages(dynamic stagesData) {
    try {
      if (stagesData is List) {
        return stagesData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return FermentationStage.fromMap(e);
                } else if (e is Map) {
                  return FermentationStage.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing stage: $e', e);
                return null;
              }
            })
            .where((stage) => stage != null)
            .cast<FermentationStage>()
            .toList();
      }
      return const <FermentationStage>[];
    } catch (e) {
      AppLogger.error('Error parsing stages list: $e', e);
      return const <FermentationStage>[];
    }
  }

  static List<String> _parsePhotos(dynamic photosData) {
    try {
      if (photosData is List) {
        return photosData
            .map((e) => e.toString())
            .where((photo) => photo.isNotEmpty)
            .toList();
      }
      return const <String>[];
    } catch (e) {
      AppLogger.error('Error parsing photos list: $e', e);
      return const <String>[];
    }
  }
}