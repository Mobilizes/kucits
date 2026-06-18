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

  Stream<List<CatPost>> streamPostsForUser(String userId) {
    try {
      return _db
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => CatPost.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return posts;
      });
    } catch (_) {
      return const Stream.empty();
    }
  }
  
  Stream<List<CatPost>> streamPostsForCat(String catId, {bool sortByPopularity = false}) {
    try {
      return _db
          .collection('posts')
          .where('catIds', arrayContains: catId)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => CatPost.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        if (sortByPopularity) {
          posts.sort((a, b) {
            final likeCompare = b.likes.compareTo(a.likes);
            if (likeCompare != 0) return likeCompare;
            return b.timestamp.compareTo(a.timestamp);
          });
        } else {
          posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        return posts;
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
        final userDoc = await transaction.get(_db.collection('users').doc(userId));

        if (!postDoc.exists) return;

        final currentLikes = postDoc.data()?['likes'] as int? ?? 0;

        if (likeDoc.exists) {
          transaction.delete(likeRef);
          transaction.update(postRef, {'likes': (currentLikes - 1).clamp(0, 999999)});
        } else {
          transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(postRef, {'likes': currentLikes + 1});

          final authorId = postDoc.data()?['authorId'] as String?;
          if (authorId != null && authorId != userId) {
            final likerUsername = userDoc.exists ? (userDoc.data()?['username'] as String? ?? 'Someone') : 'Someone';
            final likerAvatarUrl = userDoc.exists ? (userDoc.data()?['profilePictureUrl'] as String? ?? '') : '';

            final notificationRef = _db.collection('notifications').doc();
            transaction.set(notificationRef, {
              'recipientId': authorId,
              'senderId': userId,
              'senderUsername': likerUsername,
              'senderAvatarUrl': likerAvatarUrl,
              'type': 'like',
              'postId': postId,
              'title': 'New Like',
              'body': '$likerUsername liked your encounter post',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
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

        final authorId = postDoc.data()?['authorId'] as String?;
        if (authorId != null && authorId != comment.authorId) {
          final notificationRef = _db.collection('notifications').doc();
          transaction.set(notificationRef, {
            'recipientId': authorId,
            'senderId': comment.authorId,
            'senderUsername': comment.authorUsername,
            'senderAvatarUrl': comment.authorAvatarUrl,
            'type': 'comment',
            'postId': postId,
            'title': 'New Comment',
            'body': '${comment.authorUsername} commented: "${comment.text}"',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CatPost?> getPost(String postId) async {
    try {
      final doc = await _db.collection('posts').doc(postId).get();
      if (doc.exists) {
        return CatPost.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final postRef = _db.collection('posts').doc(postId);
      final commentRef = postRef.collection('comments').doc(commentId);

      await _db.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentComments = postDoc.data()?['comments'] as int? ?? 0;

        transaction.delete(commentRef);
        transaction.update(postRef, {'comments': (currentComments - 1).clamp(0, 999999)});
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
