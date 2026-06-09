import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cat_post.dart';
import '../models/comment.dart';

class PostService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<CatPost>> streamFeed() {
    try {
      return _db
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => CatPost.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }
  
  Stream<List<CatPost>> streamPostsForCat(String catId, {bool sortByPopularity = false}) {
    try {
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
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<bool> createPost(CatPost post) async {
    try {
      await _db.collection('posts').add(post.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePost(CatPost post) async {
    try {
      await _db.collection('posts').doc(post.id).update(post.toMap());
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

  // Like management
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final likeRef = _db.collection('posts').doc(postId).collection('likes').doc(userId);
      final postRef = _db.collection('posts').doc(postId);

      await _db.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) return;

        final currentLikes = postDoc.data()?['likes'] as int? ?? 0;

        if (likeDoc.exists) {
          transaction.delete(likeRef);
          transaction.update(postRef, {'likes': (currentLikes - 1).clamp(0, 999999)});
        } else {
          transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(postRef, {'likes': currentLikes + 1});
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<bool> streamIsLiked(String postId, String userId) {
    try {
      return _db
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists);
    } catch (_) {
      return Stream.value(false);
    }
  }

  // Comment management
  Stream<List<Comment>> streamComments(String postId) {
    try {
      return _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Comment.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<bool> addComment(String postId, Comment comment) async {
    try {
      final postRef = _db.collection('posts').doc(postId);
      final commentRef = postRef.collection('comments').doc();

      await _db.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentComments = postDoc.data()?['comments'] as int? ?? 0;

        transaction.set(commentRef, comment.toMap());
        transaction.update(postRef, {'comments': currentComments + 1});
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
