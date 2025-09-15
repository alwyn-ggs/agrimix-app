import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  static const String collectionPath = 'comments';
  static String docPath(String id) => 'comments/$id';

  factory Comment.fromMap(String id, Map<String, dynamic> map) => Comment(
        id: id,
        postId: map['postId'] ?? '',
        authorId: map['authorId'] ?? '',
        text: map['text'] ?? '',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : null,
      );

  factory Comment.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Comment.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'authorId': authorId,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  Comment copyWith({
    String? postId,
    String? authorId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Comment(
        id: id,
        postId: postId ?? this.postId,
        authorId: authorId ?? this.authorId,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          postId == other.postId &&
          authorId == other.authorId &&
          text == other.text &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, postId, authorId, text, createdAt, updatedAt);
}