import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

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

  Future<String?> changeUsername(String uid, String currentUsername, String newUsername) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) return 'Profile not found';

      final now = DateTime.now();
      final diff = now.difference(profile.lastUsernameChange);
      if (diff.inDays < 7) {
        final daysLeft = 7 - diff.inDays;
        return 'Cooldown active: Please wait $daysLeft more day(s).';
      }

      final isAvailable = await isUsernameAvailable(newUsername);
      if (!isAvailable) {
        return 'Username is already taken';
      }

      final batch = _db.batch();

      // Delete old username
      final oldUsernameRef = _db.collection('usernames').doc(currentUsername);
      batch.delete(oldUsernameRef);

      // Set new username
      final newUsernameRef = _db.collection('usernames').doc(newUsername);
      batch.set(newUsernameRef, {'uid': uid});

      // Update user profile
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'username': newUsername,
        'lastUsernameChange': Timestamp.fromDate(now),
      });

      await batch.commit();
      return null; // Success
    } catch (e) {
      return 'An error occurred while changing username.';
    }
  }

  Future<bool> updateBio(String uid, String newBio) async {
    try {
      await _db.collection('users').doc(uid).update({'bio': newBio});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfilePictureUrl(String uid, String url) async {
    try {
      await _db.collection('users').doc(uid).update({'profilePictureUrl': url});
      return true;
    } catch (e) {
      return false;
    }
  }
}
