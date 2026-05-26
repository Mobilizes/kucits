import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addData(Map<String, dynamic> data) async {
    await _db.collection("users").add(data);
  }

  Stream<QuerySnapshot> getData() {
    return _db.collection("users").snapshots();
  }
}
