import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;
  final String profilePictureUrl;
  final String bio;
  final bool isAdmin;
  final String? adminDepartment;
  final DateTime lastUsernameChange;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.username,
    required this.profilePictureUrl,
    required this.bio,
    this.isAdmin = false,
    this.adminDepartment,
    required this.lastUsernameChange,
    required this.createdAt,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      uid: id,
      username: map['username'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      isAdmin: map['isAdmin'] as bool? ?? false,
      adminDepartment: map['adminDepartment'] as String?,
      lastUsernameChange: (map['lastUsernameChange'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserProfile.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'isAdmin': isAdmin,
      'adminDepartment': adminDepartment,
      'lastUsernameChange': Timestamp.fromDate(lastUsernameChange),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
