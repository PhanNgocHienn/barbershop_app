// lib/models/barber_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final String? description; // ✅ thêm
  final String? avatarUrl; // ✅ thêm

  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    this.description,
    this.avatarUrl,
  });

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Barber(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'], // ✅ optional
      avatarUrl: data['avatarUrl'], // ✅ optional
    );
  }

  // ✅ Thêm factory cho BarberListScreen (đang dùng fromMap)
  factory Barber.fromMap(Map<String, dynamic> data, {required String id}) {
    return Barber(
      id: id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'],
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'description': description,
      'avatarUrl': avatarUrl,
    };
  }
}
