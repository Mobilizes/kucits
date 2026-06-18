import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cat.dart';

class CatService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<Cat>> streamCats({String? department}) {
    try {
      return _db
          .collection('cats')
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        final cats = snapshot.docs
            .map((doc) => Cat.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
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

  Future<void> seedCatsIfEmpty() async {
    try {
      final snapshot = await _db.collection('cats').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final seedCats = [
          Cat(id: 'c1', name: 'Mochi', department: 'Sistem Informasi', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
          Cat(id: 'c2', name: 'Biscuit', department: 'Desain', iconUrl: '', isNeutered: false, createdAt: DateTime.now()),
          Cat(id: 'c3', name: 'Luna', department: 'Teknik Fisika', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
          Cat(id: 'c4', name: 'Oreo', department: 'Teknik Elektro', iconUrl: '', isNeutered: false, createdAt: DateTime.now()),
          Cat(id: 'c5', name: 'Pudding', department: 'Arsitektur', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
          Cat(id: 'c6', name: 'Nugget', department: 'Desain', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
        ];
        for (var cat in seedCats) {
          await _db.collection('cats').doc(cat.id).set(cat.toMap());
        }
      }
    } catch (e) {
      // Ignored, fallback silently
    }
  }
}
