import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String ownerUid;
  final String? ownerName;
  final String title;
  final String body;
  final List<String> images;
  final List<String> tags;
  final int likes;
  final List<String> likedBy;
  final List<String> savedBy;
  final DateTime createdAt;
  final String? recipeId;
  final String? recipeName;

  const Post({
    required this.id,
    required this.ownerUid,
    this.ownerName,
    required this.title,
    required this.body,
    required this.images,
    required this.tags,
    required this.likes,
    required this.likedBy,
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
        ownerName: map['ownerName'] as String?,
        title: map['title'] ?? '',
        body: map['body'] ?? map['content'] ?? '',
        images: _convertToStringList(map['images']),
        tags: _convertToStringList(map['tags']),
        likes: (map['likes'] ?? 0) as int,
        likedBy: _convertToStringList(map['likedBy']),
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
        if (ownerName != null) 'ownerName': ownerName,
        'title': title,
        'body': body,
        'images': images,
        'tags': tags,
        'likes': likes,
        'likedBy': likedBy,
        'savedBy': savedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        if (recipeId != null) 'recipeId': recipeId,
        if (recipeName != null) 'recipeName': recipeName,
      };

  Post copyWith({
    String? ownerUid,
    String? ownerName,
    String? title,
    String? body,
    List<String>? images,
    List<String>? tags,
    int? likes,
    List<String>? likedBy,
    List<String>? savedBy,
    DateTime? createdAt,
    String? recipeId,
    String? recipeName,
  }) => Post(
        id: id,
        ownerUid: ownerUid ?? this.ownerUid,
        ownerName: ownerName ?? this.ownerName,
        title: title ?? this.title,
        body: body ?? this.body,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
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
          ownerName == other.ownerName &&
          title == other.title &&
          body == other.body &&
          _listEquals(images, other.images) &&
          _listEquals(tags, other.tags) &&
          likes == other.likes &&
          _listEquals(likedBy, other.likedBy) &&
          _listEquals(savedBy, other.savedBy) &&
          createdAt == other.createdAt &&
          recipeId == other.recipeId &&
          recipeName == other.recipeName;

  @override
  int get hashCode => Object.hash(
      id, ownerUid, ownerName, title, body, Object.hashAll(images), Object.hashAll(tags), likes, Object.hashAll(likedBy), Object.hashAll(savedBy), createdAt, recipeId, recipeName);

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