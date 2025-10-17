// lib/models/barber_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id; // THÊM DÒNG NÀY
  final String name;
  final String specialty;
  final String imageUrl;

  Barber({
    required this.id, // THÊM DÒNG NÀY
    required this.name,
    required this.specialty,
    required this.imageUrl,
  });

  // Cập nhật factory constructor
  factory Barber.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Barber(
      id: doc.id, // Lấy ID của document
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
