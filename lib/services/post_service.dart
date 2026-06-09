import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cat_post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<CatPost>> streamFeed() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CatPost.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }
  
  Stream<List<CatPost>> streamPostsForCat(String catId, {bool sortByPopularity = false}) {
    Query query = _db.collection('posts').where('catIds', arrayContains: catId);
    
    if (sortByPopularity) {
      query = query.orderBy('likes', descending: true).orderBy('timestamp', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CatPost.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  Future<bool> createPost(CatPost post) async {
    try {
      await _db.collection('posts').add(post.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _db.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
