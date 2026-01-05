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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}