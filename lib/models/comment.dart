import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorAvatarUrl;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    return Comment(
      id: id,
      postId: map['postId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? '',
      authorAvatarUrl: map['authorAvatarUrl'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Comment.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Comment.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
