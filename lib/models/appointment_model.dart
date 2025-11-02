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

  /// Safely constructs an Appointment from a Firestore DocumentSnapshot.
  /// If startTime/endTime are missing or null in Firestore, we fall back to
  /// a sensible default (DateTime.now()) to avoid runtime TypeErrors.
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    // Read Timestamp fields safely (they may be null or missing)
    final Timestamp? startTimestamp = data['startTime'] is Timestamp
        ? data['startTime'] as Timestamp
        : null;
    final Timestamp? endTimestamp = data['endTime'] is Timestamp
        ? data['endTime'] as Timestamp
        : null;

    return Appointment(
      id: doc.id,
      userId: data['userId'] ?? '',
      barberId: data['barberId'] ?? '',
      serviceName: data['serviceName'] ?? 'Không rõ dịch vụ',
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      startTime: startTimestamp != null
          ? startTimestamp.toDate()
          : DateTime.now(),
      endTime: endTimestamp != null ? endTimestamp.toDate() : DateTime.now(),
      status: data['status'] ?? 'Không rõ',
    );
  }

  /// Optional: convert Appointment back to map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'barberId': barberId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
    };
  }
}
