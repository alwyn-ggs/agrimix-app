import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'farmer' or 'admin'
  final String? membershipId;
  final String? photoUrl;
  final bool approved;
  final DateTime createdAt;
  final List<String> fcmTokens;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.membershipId,
    this.photoUrl,
    required this.approved,
    required this.createdAt,
    this.fcmTokens = const [],
  });

  static const String collectionPath = 'users';
  static String docPath(String uid) => 'users/$uid';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? 'farmer',
        membershipId: map['membershipId'],
        photoUrl: map['photoUrl'],
        approved: _parseBool(map['approved']),
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : (map['createdAt'] is DateTime
                ? map['createdAt'] as DateTime
                : DateTime.now()),
        fcmTokens: List<String>.from(map['fcmTokens'] ?? const <String>[]),
      );

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return AppUser.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'membershipId': membershipId,
        'photoUrl': photoUrl,
        'approved': approved,
        'createdAt': Timestamp.fromDate(createdAt),
        'fcmTokens': fcmTokens,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? membershipId,
    String? photoUrl,
    bool? approved,
    DateTime? createdAt,
    List<String>? fcmTokens,
  }) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        membershipId: membershipId ?? this.membershipId,
        photoUrl: photoUrl ?? this.photoUrl,
        approved: approved ?? this.approved,
        createdAt: createdAt ?? this.createdAt,
        fcmTokens: fcmTokens ?? this.fcmTokens,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          name == other.name &&
          email == other.email &&
          role == other.role &&
          membershipId == other.membershipId &&
          photoUrl == other.photoUrl &&
          approved == other.approved &&
          createdAt == other.createdAt &&
          _listEquals(fcmTokens, other.fcmTokens);

  @override
  int get hashCode => Object.hash(
      uid, name, email, role, membershipId, photoUrl, approved, createdAt, Object.hashAll(fcmTokens));

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value != 0;
    }
    return false;
  }
}