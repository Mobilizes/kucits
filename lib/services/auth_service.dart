import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          await currentUser.delete();
        } catch (_) {}
      }
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final userService = UserService();
      
      // 1. Check if username is available first
      final isAvailable = await userService.isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username is already taken or database access denied.');
      }

      // Check and clean up current anonymous user before creating the new account
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          await currentUser.delete();
        } catch (_) {}
      }

      // 2. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = result.user;
      if (user != null) {
        // 3. Create Firestore Profile
        final success = await userService.createUserProfile(user.uid, email, username);
        if (!success) {
          // Fallback cleanup if profile creation fails
          await user.delete();
          throw Exception('Failed to create user profile in database.');
        }
        return user;
      }
      throw Exception('Failed to create account.');
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow; // Rethrow to let the UI catch and display the specific error
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        await user.delete();
      } else {
        await _auth.signOut();
      }
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }
}
