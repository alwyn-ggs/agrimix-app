import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String ownerUid;
  final String title;
  final String body;
  final List<String> images;
  final List<String> tags;
  final int likes;
  final List<String> savedBy;
  final DateTime createdAt;
  final String? recipeId;
  final String? recipeName;

  const Post({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.body,
    required this.images,
    required this.tags,
    required this.likes,
    required this.savedBy,
    required this.createdAt,
    this.recipeId,
    this.recipeName,
  });

  static const String collectionPath = 'posts';
  static String docPath(String id) => 'posts/$id';

  factory Post.fromMap(String id, Map<String, dynamic> map) => Post(
        id: id,
        ownerUid: map['ownerUid'] ?? map['authorId'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? map['content'] ?? '',
        images: _convertToStringList(map['images']),
        tags: _convertToStringList(map['tags']),
        likes: (map['likes'] ?? 0) as int,
        savedBy: _convertToStringList(map['savedBy']),
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        recipeId: map['recipeId'],
        recipeName: map['recipeName'],
      );

  factory Post.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Post.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'title': title,
        'body': body,
        'images': images,
        'tags': tags,
        'likes': likes,
        'savedBy': savedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        if (recipeId != null) 'recipeId': recipeId,
        if (recipeName != null) 'recipeName': recipeName,
      };

  Post copyWith({
    String? ownerUid,
    String? title,
    String? body,
    List<String>? images,
    List<String>? tags,
    int? likes,
    List<String>? savedBy,
    DateTime? createdAt,
    String? recipeId,
    String? recipeName,
  }) => Post(
        id: id,
        ownerUid: ownerUid ?? this.ownerUid,
        title: title ?? this.title,
        body: body ?? this.body,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        likes: likes ?? this.likes,
        savedBy: savedBy ?? this.savedBy,
        createdAt: createdAt ?? this.createdAt,
        recipeId: recipeId ?? this.recipeId,
        recipeName: recipeName ?? this.recipeName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerUid == other.ownerUid &&
          title == other.title &&
          body == other.body &&
          _listEquals(images, other.images) &&
          _listEquals(tags, other.tags) &&
          likes == other.likes &&
          _listEquals(savedBy, other.savedBy) &&
          createdAt == other.createdAt &&
          recipeId == other.recipeId &&
          recipeName == other.recipeName;

  @override
  int get hashCode => Object.hash(
      id, ownerUid, title, body, Object.hashAll(images), Object.hashAll(tags), likes, Object.hashAll(savedBy), createdAt, recipeId, recipeName);

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<String> _convertToStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}