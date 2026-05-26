import 'package:cloud_firestore/cloud_firestore.dart';
import 'cat.dart';

class CatPost {
  final String id;
  final List<Cat> cats;
  final List<String> catIds;
  final String ownerId;
  final String ownerName;
  final String caption;
  final String photoUrl;
  final DateTime timestamp;
  final int likes;
  final int comments;

  CatPost({
    required this.id,
    required this.cats,
    required this.catIds,
    required this.ownerId,
    required this.ownerName,
    required this.caption,
    required this.photoUrl,
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
      ownerId: map['ownerId'] as String,
      ownerName: (map['ownerName'] as String?) ?? '',
      caption: map['caption'] as String,
      photoUrl: (map['photoUrl'] as String?) ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      likes: (map['likes'] as int?) ?? 0,
      comments: (map['comments'] as int?) ?? 0,
    );
  }

  factory CatPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      CatPost.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() => {
        'cats': cats.map((c) => {'id': c.id, ...c.toMap()}).toList(),
        'catIds': cats.map((c) => c.id).toList(),
        'ownerId': ownerId,
        'ownerName': ownerName,
        'caption': caption,
        'photoUrl': photoUrl,
        'timestamp': Timestamp.fromDate(timestamp),
        'likes': likes,
        'comments': comments,
      };
}
