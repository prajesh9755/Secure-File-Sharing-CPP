// auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for user login/logout status
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Handles both Login and Registration.
  Future<String> handleAuth(
    String email, 
    String password, {
    required bool isRegister,
  }) async {
    try {
      if (isRegister) {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return 'Registration successful!';
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return 'Login successful!';
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Send password reset email
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset email sent successfully!';
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Check if email exists in Firebase
  Future<bool> checkEmailExists(String email) async {
    try {
      // Create user with email only - this will fail if user already exists
      await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: 'temporary_password_123456789'
      );
      
      // If we reach here, user was created successfully, so we need to delete it
      try {
        await _auth.currentUser?.delete();
      } catch (e) {
        // Ignore deletion errors
      }
      
      return false; // User didn't exist before
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true; // User exists
      } else if (e.code == 'invalid-email') {
        return false; // Invalid email format
      }
      return false; // Assume user doesn't exist for other errors
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}