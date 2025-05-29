import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Attempting to sign in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful. User ID: ${credential.user?.uid}');
      notifyListeners();
      return credential;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Attempting to create account with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Account creation successful. User ID: ${credential.user?.uid}');
      notifyListeners();
      return credential;
    } catch (e) {
      print('Account creation error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      notifyListeners();
    } else {
      throw Exception('No user is currently signed in');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is currently signed in');

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  /// Generate and send a 4-digit code for password reset
  Future<void> sendVerificationCode({
    required String email,
    required String type, // Only 'reset' is supported now
  }) async {
    final code = (Random().nextInt(9000) + 1000).toString();
    final now = DateTime.now();
    await _firestore.collection('verificationCodes').doc(email).set({
      'code': code,
      'type': type,
      'timestamp': now.toIso8601String(),
      'used': false,
    });
    debugPrint('Password reset code for $email: $code');
  }

  /// Reset password after code verification
  Future<void> resetPasswordWithCode({
    required String email,
    required String newPassword,
  }) async {
    // For demo: just send a password reset email
    await _auth.sendPasswordResetEmail(email: email);
  }
}
