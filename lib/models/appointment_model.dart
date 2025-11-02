// lib/models/appointment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String barberId;
  final String serviceName;
  final double servicePrice;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  String barberName = 'Đang tải...';
  String barberImageUrl = '';

  Appointment({
    required this.id,
    required this.userId,
    required this.barberId,
    required this.serviceName,
    required this.servicePrice,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      userId: data['userId'] ?? '',
      barberId: data['barberId'] ?? '',
      serviceName: data['serviceName'] ?? 'Không rõ dịch vụ',
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'Không rõ',
    );
  }
}
