import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class UsersRepo {
  final AuthService _auth;
  final FirestoreService _fs;

  UsersRepo(this._auth, this._fs);

  Stream<AppUser?> watchMe() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield null;
    } else {
      final doc = await _fs.db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        yield AppUser.fromMap(doc.id, doc.data()!);
      } else {
        yield null; // User document doesn't exist
      }
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _fs.db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> createUser(AppUser user) async {
    try {
      AppLogger.debug('UsersRepo: Creating user document for ${user.uid}');
      AppLogger.debug('UsersRepo: User data: ${user.toMap()}');
      AppLogger.debug('UsersRepo: User role: ${user.role}');
      AppLogger.debug('UsersRepo: User approved: ${user.approved}');
      await _fs.db.collection('users').doc(user.uid).set(user.toMap());
      AppLogger.info('UsersRepo: User document created successfully in Firestore');
      
      // Verify the document was created correctly
      final doc = await _fs.db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final createdUser = AppUser.fromMap(doc.id, doc.data()!);
        AppLogger.info('UsersRepo: Verification - Created user: ${createdUser.name}, Role: ${createdUser.role}, Approved: ${createdUser.approved}');
      } else {
        AppLogger.error('UsersRepo: ERROR - Document was not created!');
      }
    } catch (e) {
      AppLogger.error('UsersRepo: Error creating user: $e', e);
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      AppLogger.debug('UsersRepo: Updating user document for ${user.uid}');
      final data = user.toMap();
      AppLogger.debug('UsersRepo: Updated user data: $data');
      // Use update() to ensure field types are overwritten (e.g., string -> bool)
      await _fs.db.collection('users').doc(user.uid).update(data);
      AppLogger.info('UsersRepo: User document updated successfully with update()');

      // Verify persisted value
      final doc = await _fs.db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final saved = AppUser.fromMap(doc.id, doc.data()!);
        AppLogger.info('UsersRepo: Post-update verification -> approved: ${saved.approved}, role: ${saved.role}');
      } else {
        AppLogger.warning('UsersRepo: Post-update verification failed: doc not found');
      }
    } catch (e) {
      AppLogger.error('UsersRepo: Error updating user: $e', e);
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> setApproved(String uid, bool approved) async {
    try {
      AppLogger.debug('UsersRepo: setApproved -> uid: $uid, approved: $approved');
      await _fs.db.collection('users').doc(uid).update({'approved': approved});
      AppLogger.info('UsersRepo: setApproved write completed');
      final doc = await _fs.db.collection('users').doc(uid).get();
      if (doc.exists) {
        final saved = AppUser.fromMap(doc.id, doc.data()!);
        AppLogger.info('UsersRepo: setApproved verification -> approved: ${saved.approved}');
      } else {
        AppLogger.warning('UsersRepo: setApproved verification failed: doc not found');
      }
    } catch (e) {
      AppLogger.error('UsersRepo: Error in setApproved: $e', e);
      throw Exception('Failed to set approved: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _fs.db.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Stream<List<AppUser>> watchAllUsers() {
    AppLogger.debug('UsersRepo: Starting watchAllUsers stream');
    AppLogger.debug('UsersRepo: Firestore service: OK');
    AppLogger.debug('UsersRepo: Firestore DB: OK');
    
    return _fs.db.collection('users').snapshots().map((snapshot) {
      AppLogger.debug('UsersRepo: Received snapshot with ${snapshot.docs.length} documents');
      AppLogger.debug('UsersRepo: Snapshot metadata: ${snapshot.metadata}');
      AppLogger.debug('UsersRepo: Snapshot from cache: ${snapshot.metadata.isFromCache}');
      
      final users = snapshot.docs.map((doc) {
        AppLogger.debug('UsersRepo: Processing document ${doc.id}');
        AppLogger.debug('UsersRepo: Document data: ${doc.data()}');
        final user = AppUser.fromMap(doc.id, doc.data());
        AppLogger.debug('UsersRepo: Parsed user: ${user.name}, role: ${user.role}, approved: ${user.approved}');
        return user;
      }).toList();
      
      AppLogger.debug('UsersRepo: Returning ${users.length} users from stream');
      return users;
    });
  }

  Stream<List<AppUser>> watchPendingUsers() {
    AppLogger.debug('UsersRepo: Starting watchPendingUsers stream');
    // Most robust: read all users and filter client-side to avoid index/type issues
    return _fs.db
        .collection('users')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      AppLogger.debug('UsersRepo: watchPendingUsers snapshot with ${snapshot.docs.length} docs');
      final users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .where((u) => u.role == 'farmer' && u.approved == false)
          .toList();
      AppLogger.debug('UsersRepo: watchPendingUsers filtered pending farmers: ${users.length}');
      return users;
    });
  }

  Stream<int> watchPendingUsersCount() {
    AppLogger.debug('UsersRepo: Starting watchPendingUsersCount stream');
    return _fs.db
        .collection('users')
        .where('role', isEqualTo: 'farmer')
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .where((u) => u.role == 'farmer' && u.approved == false)
          .length;
      AppLogger.debug('UsersRepo: watchPendingUsersCount pending farmers: $count');
      return count;
    });
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      AppLogger.debug('UsersRepo: Fetching all users from Firestore');
      final snapshot = await _fs.db.collection('users').get();
      final users = snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
      AppLogger.info('UsersRepo: Found ${users.length} users');
      for (var user in users) {
        AppLogger.debug('UsersRepo: User - ${user.name}, Role: ${user.role}, Approved: ${user.approved}');
      }
      return users;
    } catch (e) {
      AppLogger.error('UsersRepo: Error fetching users: $e', e);
      throw Exception('Failed to get all users: $e');
    }
  }
}