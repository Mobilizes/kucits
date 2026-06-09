import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final doc = await _db.collection('usernames').doc(username).get();
      return !doc.exists;
    } catch (e) {
      return false; // Safest default on error
    }
  }

  Future<bool> createUserProfile(String uid, String email, String username) async {
    try {
      // Create user profile
      final userProfile = UserProfile(
        uid: uid,
        username: username,
        profilePictureUrl: '',
        bio: '',
        lastUsernameChange: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // We use a batch to ensure both the user doc and username registry are written atomically
      final batch = _db.batch();
      
      final userRef = _db.collection('users').doc(uid);
      batch.set(userRef, userProfile.toMap());

      final usernameRef = _db.collection('usernames').doc(username);
      batch.set(usernameRef, {'uid': uid});

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
