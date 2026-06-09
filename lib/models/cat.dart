import 'package:cloud_firestore/cloud_firestore.dart';

class Cat {
  final String id;
  final String name;
  final String department;
  final String iconUrl;
  final bool isNeutered;
  final DateTime createdAt;

  Cat({
    required this.id,
    required this.name,
    required this.department,
    required this.iconUrl,
    required this.isNeutered,
    required this.createdAt,
  });

  factory Cat.fromMap(String id, Map<String, dynamic> map) {
    return Cat(
      id: id,
      name: map['name'] as String? ?? '',
      department: map['department'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      isNeutered: map['isNeutered'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Cat.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Cat.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'iconUrl': iconUrl,
      'isNeutered': isNeutered,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
