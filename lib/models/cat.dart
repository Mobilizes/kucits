import 'package:cloud_firestore/cloud_firestore.dart';

class Cat {
  final String id;
  final String name;
  final String breed;
  final String iconUrl;

  Cat({
    required this.id,
    required this.name,
    required this.breed,
    this.iconUrl = '',
  });

  factory Cat.fromMap(String id, Map<String, dynamic> map) => Cat(
        id: id,
        name: map['name'] as String,
        breed: map['breed'] as String,
        iconUrl: (map['iconUrl'] as String?) ?? '',
      );

  factory Cat.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Cat.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() => {
        'name': name,
        'breed': breed,
        'iconUrl': iconUrl,
      };
}
