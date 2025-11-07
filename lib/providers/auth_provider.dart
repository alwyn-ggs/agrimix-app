import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import '../services/error_handler_service.dart';
import '../repositories/users_repo.dart';
import '../models/user.dart';
import '../utils/logger.dart';


class AuthProvider extends ChangeNotifier with ErrorHandlerMixin {
  final AuthService auth;
  final UsersRepo usersRepo;
  final MessagingService messaging;
  final NotificationService? notificationService;
  bool loading = false;
  User? _currentUser;
  AppUser? _currentAppUser;
  bool _rememberMe = false;

  AuthProvider(this.auth, this.usersRepo, this.messaging, [this.notificationService]) {
    _init();
  }

  User? get currentUser => _currentUser;
  AppUser? get currentAppUser => _currentAppUser;
  bool get isLoggedIn => _currentUser != null;
  String? get userRole => _currentAppUser?.role;
  bool get rememberMe => _rememberMe;

  void _init() {
    AppLogger.debug('AuthProvider: Initializing...');
    // Immediate initialization with Firebase readiness check
    _initializeWithReadinessCheck();
  }

  Future<void> _initializeWithReadinessCheck() async {
    try {
      AppLogger.debug('AuthProvider: Starting SIMPLIFIED initialization for fresh install...');
      
      // Load remember-me preference first
      await _loadRememberPreference();
      
      // Set up auth state listener with simplified handling
      AppLogger.debug('AuthProvider: Setting up SIMPLIFIED auth state listener...');
      auth.authStateChanges().listen(
        (User? user) {
          AppLogger.debug('AuthProvider: Auth state changed - user: ${user?.uid}');
          _currentUser = user;
          
          if (user == null) {
            // User signed out
            _currentAppUser = null;
            loading = false;
            AppLogger.debug('AuthProvider: User signed out, clearing state');
            notifyListeners();
          } else {
            // User is signed in - check if we need to load user data
            if (_currentAppUser == null) {
              AppLogger.debug('AuthProvider: User signed in but no app user data, loading...');
              _loadUserDataDirectly(user.uid).catchError((e) {
                AppLogger.error('AuthProvider: Failed to load user data in auth state listener: $e', e);
                loading = false;
                notifyListeners();
              });
            }
          }
        },
        onError: (error) {
          AppLogger.debug('AuthProvider: Auth state error: $error');
          handleError(error, context: 'Auth state change');
          loading = false;
          notifyListeners();
        },
      );
      
      AppLogger.debug('AuthProvider: Simplified initialization completed');
      
    } catch (error) {
      AppLogger.error('AuthProvider: Failed to initialize: $error', error);
      loading = false;
      notifyListeners();
    }
  }




  Stream<User?> get currentUserStream => auth.authStateChanges();

  Future<void> signIn(String email, String password, {bool rememberMe = false}) async {
    // Prevent multiple simultaneous login attempts
    if (loading) {
      AppLogger.debug('AuthProvider: Login already in progress, ignoring duplicate request');
      return;
    }
    
    loading = true;
    clearError();
    notifyListeners();
    
    try {
      // Save remember-me preference immediately for this session
      _rememberMe = rememberMe;
      AppLogger.debug('AuthProvider: Starting DIRECT sign in for fresh install...');
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);
      } catch (e) {
        AppLogger.debug('AuthProvider: Error saving remember_me preference: $e');
      }

      // DIRECT Firebase Auth sign in - no delays, no complex checks
      AppLogger.debug('AuthProvider: Attempting Firebase Auth sign in...');
      await auth.signIn(email, password);
      AppLogger.debug('AuthProvider: Firebase Auth sign in SUCCESS');
      
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        AppLogger.debug('AuthProvider: Got user UID: $uid, loading user data DIRECTLY...');
        
        // DIRECT user data loading for fresh install
        await _loadUserDataDirectly(uid);
        
        // Handle FCM token in background (non-blocking)
        _handleFCMTokenSafely(uid);
      } else {
        throw Exception('No user UID after successful sign in');
      }
      
    } catch (e) {
      AppLogger.error('AuthProvider: Sign in failed: $e', e);
      // Do NOT escalate to global error page; show inline on login screen instead
      final message = ErrorHandlerService.getUserFriendlyMessage(e, null);
      setErrorMessage(message);
      loading = false;
      notifyListeners();
    }
  }

  /// Google Sign-In flow
  Future<void> signInWithGoogle() async {
    if (loading) return;
    loading = true;
    clearError();
    notifyListeners();

    try {
      AppLogger.debug('AuthProvider: Starting Google sign-in...');
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        AppLogger.debug('AuthProvider: Google sign-in cancelled by user');
        loading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final uid = auth.currentUser?.uid;
      if (uid != null) {
        AppLogger.debug('AuthProvider: Google sign-in success, uid: $uid');
        // Load or create user document then complete login
        await _loadUserDataDirectly(uid);
        _handleFCMTokenSafely(uid);
      } else {
        throw Exception('No user UID after Google sign-in');
      }
    } catch (e) {
      AppLogger.error('AuthProvider: Google sign-in failed: $e', e);
      setErrorMessage(ErrorHandlerService.getUserFriendlyMessage(e, null));
      loading = false;
      notifyListeners();
    }
  }

  /// Direct user data loading for fresh installs - no complex retry logic
  Future<void> _loadUserDataDirectly(String uid) async {
    try {
      AppLogger.debug('AuthProvider: DIRECT user data loading for uid: $uid');
      
      // Try to get user data with reasonable timeout
      _currentAppUser = await usersRepo.getUser(uid).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null, // Return null instead of throwing
      );
      
      if (_currentAppUser != null) {
        AppLogger.debug('AuthProvider: User data found! Name: ${_currentAppUser!.name}, Role: ${_currentAppUser!.role}');
        await _completeLoginProcess();
        return;
      }
      
      // If user document doesn't exist, create it immediately
      AppLogger.debug('AuthProvider: User document not found, creating new user...');
      await _createUserDocumentDirectly(uid);
      
    } catch (e) {
      AppLogger.error('AuthProvider: Direct user data loading failed: $e');
      // Don't throw - try to create user document as fallback
      await _createUserDocumentDirectly(uid);
    }
  }

  /// Create user document directly for fresh installs
  Future<void> _createUserDocumentDirectly(String uid) async {
    try {
      final firebaseUser = _currentUser ?? auth.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('No valid Firebase user data');
      }
      
      // Determine if admin based on email
      final email = firebaseUser.email!.toLowerCase();
      final isAdmin = email.contains('admin') || 
                      email.endsWith('@agrimix.com') ||
                      email.contains('administrator');
      
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        role: isAdmin ? 'admin' : 'farmer',
        approved: isAdmin ? true : false, // Auto-approve admins
        createdAt: DateTime.now(),
      );
      
      AppLogger.debug('AuthProvider: Creating user - Email: ${newUser.email}, Role: ${newUser.role}, Approved: ${newUser.approved}');
      
      // Create user document with timeout
      await usersRepo.createUser(newUser).timeout(const Duration(seconds: 8));
      
      // Small delay for Firestore consistency
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify creation
      _currentAppUser = await usersRepo.getUser(uid).timeout(const Duration(seconds: 5));
      
      if (_currentAppUser != null) {
        AppLogger.debug('AuthProvider: User created successfully! Role: ${_currentAppUser!.role}');
        await _completeLoginProcess();
      } else {
        throw Exception('User creation verification failed');
      }
      
    } catch (e) {
      AppLogger.error('AuthProvider: User creation failed: $e');
      loading = false;
      notifyListeners();
      handleError(Exception('Failed to set up your account. Please try again.'), context: 'User creation');
    }
  }

  /// Complete the login process
  Future<void> _completeLoginProcess() async {
    try {
      // Subscribe to announcements (non-blocking)
      messaging.subscribeToTopic('announcements').catchError((e) {
        AppLogger.debug('AuthProvider: Failed to subscribe to announcements (non-fatal): $e');
      });
      
      // Deliver pending notifications (non-blocking)
      if (notificationService != null && _currentAppUser != null) {
        notificationService!.deliverPendingNotifications(_currentAppUser!.uid).catchError((e) {
          AppLogger.debug('AuthProvider: Failed to deliver notifications (non-fatal): $e');
        });
      }
      
      AppLogger.debug('AuthProvider: LOGIN COMPLETED! User: ${_currentAppUser!.name}, Role: ${_currentAppUser!.role}');
      
      loading = false;
      notifyListeners();
      
    } catch (e) {
      AppLogger.warning('AuthProvider: Non-critical completion tasks failed: $e');
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name, {String? membershipId}) async {
    loading = true;
    clearError();
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
      handleError(e, context: 'Registration');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    AppLogger.debug('AuthProvider: Signing out user');
    await auth.signOut();
    _currentUser = null;
    _currentAppUser = null;
    _rememberMe = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);
      AppLogger.debug('AuthProvider: Cleared remember_me preference');
    } catch (e) {
      AppLogger.debug('AuthProvider: Error clearing remember_me preference: $e');
    }
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    loading = true;
    clearError();
    notifyListeners();
    try {
      await auth.sendPasswordResetEmail(email);
    } catch (e) {
      handleError(e, context: 'Password reset');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    AppLogger.debug('AuthProvider: Starting refresh - _currentUser: ${_currentUser?.uid}, Firebase user: ${auth.currentUser?.uid}');
    
    if (_currentUser != null) {
      AppLogger.debug('AuthProvider: Refreshing current user data');
      await _loadUserDataDirectly(_currentUser!.uid);
    } else {
      AppLogger.debug('AuthProvider: No current user to refresh, checking auth state');
      // Force check the current auth state
      final currentFirebaseUser = auth.currentUser;
      if (currentFirebaseUser != null) {
        AppLogger.debug('AuthProvider: Found Firebase user, loading data');
        _currentUser = currentFirebaseUser;
        loading = true;
        notifyListeners();
        await _loadUserDataDirectly(currentFirebaseUser.uid);
      } else {
        AppLogger.debug('AuthProvider: No Firebase user found - user may need to log in again');
        // Clear any stale app user data
        _currentAppUser = null;
        loading = false;
        notifyListeners();
        // Show error to user that they need to log in again
        handleError(Exception('Your session has expired. Please log in again.'), context: 'Session refresh');
      }
    }
  }

  /// Force reset authentication state - useful for troubleshooting
  Future<void> resetAuthState() async {
    AppLogger.debug('AuthProvider: Resetting authentication state');
    loading = false;
    _currentUser = null;
    _currentAppUser = null;
    clearError();
    notifyListeners();
    
    // Check current Firebase Auth state
    final currentFirebaseUser = auth.currentUser;
    if (currentFirebaseUser != null) {
      AppLogger.debug('AuthProvider: Found Firebase user after reset, reloading');
      _currentUser = currentFirebaseUser;
      loading = true;
      notifyListeners();
      await _loadUserDataDirectly(currentFirebaseUser.uid);
    }
  }

  Future<void> _loadRememberPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me') ?? false;
      AppLogger.debug('AuthProvider: Loaded remember_me preference: $_rememberMe');
    } catch (e) {
      AppLogger.debug('AuthProvider: Error loading remember_me preference: $e');
      _rememberMe = false;
    }
  }

  /// Handle FCM token operations safely without blocking authentication
  void _handleFCMTokenSafely(String uid) {
    // Run in background, don't await
    Future.delayed(Duration.zero, () async {
      try {
        final token = await messaging.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            AppLogger.info('FCM token request timed out (non-fatal)');
            return null;
          },
        );
        
        if (token != null) {
          await messaging.saveTokenToUser(uid, token).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.info('FCM token save timed out (non-fatal)');
            },
          );
          AppLogger.debug('FCM token saved successfully');
        }
        
        // Set up token refresh listener
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          messaging.saveTokenToUser(uid, newToken).catchError((error) {
            AppLogger.info('FCM token refresh save failed (non-fatal): $error');
          });
        });
      } catch (e) {
        // Log but don't throw - FCM issues shouldn't block authentication
        if (e.toString().contains('GoogleApiManager') || 
            e.toString().contains('SecurityException')) {
          AppLogger.info('Google Play Services warning during FCM setup (non-fatal): $e');
        } else {
          AppLogger.warning('FCM token setup failed (non-fatal): $e');
        }
      }
    });
  }

}