import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime createdAt;
  final String createdBy;
  final List<String> cropTargets; // Optional crop targeting
  final bool pushSent; // Track if push notification was sent

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.pinned,
    required this.createdAt,
    required this.createdBy,
    this.cropTargets = const [],
    this.pushSent = false,
  });

  static const String collectionPath = 'announcements';
  static String docPath(String id) => 'announcements/$id';

  factory Announcement.fromMap(String id, Map<String, dynamic> map) => Announcement(
        id: id,
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        pinned: (map['pinned'] ?? false) as bool,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        createdBy: map['createdBy'] ?? '',
        cropTargets: List<String>.from(map['cropTargets'] ?? const <String>[]),
        pushSent: (map['pushSent'] ?? false) as bool,
      );

  factory Announcement.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Announcement.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'pinned': pinned,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'cropTargets': cropTargets,
        'pushSent': pushSent,
      };

  Announcement copyWith({
    String? title,
    String? body,
    bool? pinned,
    DateTime? createdAt,
    String? createdBy,
    List<String>? cropTargets,
    bool? pushSent,
  }) => Announcement(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy ?? this.createdBy,
        cropTargets: cropTargets ?? this.cropTargets,
        pushSent: pushSent ?? this.pushSent,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          pinned == other.pinned &&
          createdAt == other.createdAt &&
          createdBy == other.createdBy &&
          _listEquals(cropTargets, other.cropTargets) &&
          pushSent == other.pushSent;

  @override
  int get hashCode => Object.hash(id, title, body, pinned, createdAt, createdBy, Object.hashAll(cropTargets), pushSent);

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}