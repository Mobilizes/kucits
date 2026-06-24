import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cat.dart';

class CatService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<Cat>> streamCats({String? department}) {
    try {
      return _db.collection('cats').orderBy('name').snapshots().map((snapshot) {
        final cats = snapshot.docs
            .map(
              (doc) => Cat.fromSnapshot(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ),
            )
            .toList();
        if (department != null && department.isNotEmpty) {
          return cats.where((c) => c.department == department).toList();
        }
        return cats;
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<Cat?> getCat(String catId) async {
    try {
      final doc = await _db.collection('cats').doc(catId).get();
      if (doc.exists) {
        return Cat.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Admin only functions below
  Future<bool> addCat(Cat cat) async {
    try {
      await _db.collection('cats').doc(cat.id).set(cat.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCat(String catId) async {
    try {
      await _db.collection('cats').doc(catId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCat(Cat cat) async {
    try {
      await _db.collection('cats').doc(cat.id).update(cat.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }
}
