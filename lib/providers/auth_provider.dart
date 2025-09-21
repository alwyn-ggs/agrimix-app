import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../repositories/users_repo.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService auth;
  final UsersRepo usersRepo;
  final MessagingService messaging;
  bool loading = false;
  String? error;
  User? _currentUser;
  AppUser? _currentAppUser;

  AuthProvider(this.auth, this.usersRepo, this.messaging) {
    _init();
  }

  User? get currentUser => _currentUser;
  AppUser? get currentAppUser => _currentAppUser;
  bool get isLoggedIn => _currentUser != null;
  String? get userRole => _currentAppUser?.role;

  void _init() {
    AppLogger.debug('AuthProvider: Initializing...');
    // Listen to auth state changes
    auth.authStateChanges().listen(
      (User? user) {
        AppLogger.debug('AuthProvider: Auth state changed - user: ${user?.uid}');
        _currentUser = user;
        if (user != null) {
          // Enter loading state while fetching Firestore user document
          loading = true;
          notifyListeners();
          // Load user data from Firestore
          _loadUserData(user.uid);
        } else {
          _currentAppUser = null;
          loading = false; // Set loading to false when no user
          AppLogger.debug('AuthProvider: No user, setting loading to false');
          notifyListeners();
        }
      },
      onError: (error) {
        AppLogger.debug('AuthProvider: Auth state error: $error');
        this.error = error.toString();
        loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadUserData(String uid) async {
    try {
      loading = true;
      notifyListeners();
      AppLogger.debug('AuthProvider: Loading user data for uid: $uid');
      _currentAppUser = await usersRepo.getUser(uid);
      
      // Subscribe to announcements topic for all users
      try {
        await messaging.subscribeToTopic('announcements');
        AppLogger.debug('AuthProvider: Subscribed to announcements topic');
      } catch (e) {
        AppLogger.debug('AuthProvider: Failed to subscribe to announcements topic: $e');
        // Non-fatal error, continue
      }
      
      loading = false; // Set loading to false when user data is loaded
      AppLogger.debug('AuthProvider: User data loaded successfully');
      AppLogger.debug('AuthProvider: User approved status: ${_currentAppUser?.approved}');
      AppLogger.debug('AuthProvider: User role: ${_currentAppUser?.role}');
      notifyListeners();
    } catch (e) {
      AppLogger.debug('AuthProvider: Error loading user data: $e');
      error = e.toString();
      loading = false; // Set loading to false even on error
      notifyListeners();
    }
  }

  Stream<User?> get currentUserStream => auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await auth.signIn(email, password);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        try {
          final token = await messaging.getToken();
          if (token != null) {
            await messaging.saveTokenToUser(uid, token);
          }
        } catch (e) {
          // Non-fatal: permission may be blocked
          AppLogger.warning('AuthProvider.signIn: skipping token save due to error: $e');
        }
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          messaging.saveTokenToUser(uid, newToken);
        });
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password, String name, {String? membershipId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      AppLogger.debug('AuthProvider: Starting registration for $email');
      final userCredential = await auth.register(email, password);
      if (userCredential.user != null) {
        // Create user document in Firestore
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          role: 'farmer', // Default role
          membershipId: membershipId,
          approved: false, // Requires admin approval
          createdAt: DateTime.now(),
          fcmTokens: [],
        );
        AppLogger.debug('AuthProvider: Creating user document with:');
        AppLogger.debug('  - UID: ${appUser.uid}');
        AppLogger.debug('  - Name: ${appUser.name}');
        AppLogger.debug('  - Email: ${appUser.email}');
        AppLogger.debug('  - Role: ${appUser.role}');
        AppLogger.debug('  - Approved: ${appUser.approved}');
        AppLogger.debug('  - Membership ID: ${appUser.membershipId}');
        await usersRepo.createUser(appUser);
        AppLogger.debug('AuthProvider: User document created successfully in Firestore');

        // Save FCM token
        final token = await messaging.getToken();
        if (token != null) {
          await messaging.saveTokenToUser(appUser.uid, token);
        }
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          messaging.saveTokenToUser(appUser.uid, newToken);
        });
      }
    } catch (e) {
      AppLogger.debug('AuthProvider: Error during registration: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _currentUser = null;
    _currentAppUser = null;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await auth.sendPasswordResetEmail(email);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      AppLogger.debug('AuthProvider: Refreshing current user data');
      await _loadUserData(_currentUser!.uid);
    }
  }
}