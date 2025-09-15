import 'package:firebase_auth/firebase_auth.dart';
import '../utils/exceptions.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Validates if the provided password matches the user's password
  /// Throws a proper exception if the password doesn't match
  Future<void> validateUserPassword(String email, String password) async {
    try {
      // Try to sign in with the provided credentials
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // If successful, sign out immediately as we were just validating
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const PasswordMismatchException(
          'The password you entered does not match the account password. Please verify the password and try again.',
          code: 'WRONG_PASSWORD'
        );
      } else if (e.code == 'user-not-found') {
        throw const UserAccountException(
          'User account not found. Please verify the email address.',
          code: 'USER_NOT_FOUND'
        );
      } else if (e.code == 'user-disabled') {
        throw const UserAccountException(
          'This user account has been disabled and cannot be approved.',
          code: 'USER_DISABLED'
        );
      } else if (e.code == 'too-many-requests') {
        throw const UserAuthenticationException(
          'Too many failed attempts. Please wait before trying again.',
          code: 'TOO_MANY_REQUESTS'
        );
      } else if (e.code == 'network-request-failed') {
        throw const UserAuthenticationException(
          'Network error. Please check your internet connection and try again.',
          code: 'NETWORK_ERROR'
        );
      } else {
        throw UserAuthenticationException(
          'Authentication failed: ${e.message ?? 'Unknown error occurred'}',
          code: e.code
        );
      }
    } catch (e) {
      if (e is PasswordMismatchException || e is UserAccountException || e is UserAuthenticationException) {
        rethrow;
      }
      throw UserAuthenticationException(
        'Failed to validate password: ${e.toString()}',
        code: 'VALIDATION_ERROR'
      );
    }
  }
}