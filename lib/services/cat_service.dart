import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cat.dart';

class CatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Cat>> streamCats({String? department}) {
    Query query = _db.collection('cats');
    
    if (department != null && department.isNotEmpty) {
      query = query.where('department', isEqualTo: department);
    }
    
    // Sort by name by default
    query = query.orderBy('name');

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cat.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    });
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
      await _db.collection('cats').add(cat.toMap());
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
