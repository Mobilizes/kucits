import 'package:cloud_firestore/cloud_firestore.dart';
import 'cat.dart';

class CatPost {
  final String id;
  final List<Cat> cats;
  final List<String> catIds;
  final String authorId;
  final String authorUsername;
  final String authorAvatarUrl;
  final String caption;
  final List<String> photoUrls;
  final GeoPoint? location;
  final DateTime timestamp;
  final int likes;
  final int comments;

  CatPost({
    required this.id,
    required this.cats,
    required this.catIds,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.caption,
    required this.photoUrls,
    this.location,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
  });

  factory CatPost.fromMap(String id, Map<String, dynamic> map) {
    final catsData = (map['cats'] as List<dynamic>?) ?? [];
    return CatPost(
      id: id,
      cats: catsData.map((c) {
        final m = c as Map<String, dynamic>;
        return Cat.fromMap(m['id'] as String, m);
      }).toList(),
      catIds: List<String>.from((map['catIds'] as List<dynamic>?) ?? []),
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? '',
      authorAvatarUrl: map['authorAvatarUrl'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      photoUrls: List<String>.from((map['photoUrls'] as List<dynamic>?) ?? []),
      location: map['location'] as GeoPoint?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
    );
  }

  factory CatPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      CatPost.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'cats': cats.map((c) => {'id': c.id, ...c.toMap()}).toList(),
      'catIds': catIds,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'caption': caption,
      'photoUrls': photoUrls,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
    };
  }
}
