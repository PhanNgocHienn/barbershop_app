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
    
    // Xử lý startTime với null check
    Timestamp? startTimeStamp = data['startTime'] as Timestamp?;
    if (startTimeStamp == null && data['appointmentTime'] != null) {
      // Fallback: nếu startTime null nhưng có appointmentTime, dùng appointmentTime
      startTimeStamp = data['appointmentTime'] as Timestamp?;
    }
    
    // Xử lý endTime với null check
    Timestamp? endTimeStamp = data['endTime'] as Timestamp?;
    if (endTimeStamp == null && startTimeStamp != null) {
      // Nếu endTime null, tính toán từ startTime (giả sử duration 60 phút mặc định)
      endTimeStamp = Timestamp.fromDate(startTimeStamp.toDate().add(const Duration(minutes: 60)));
    }
    
    if (startTimeStamp == null || endTimeStamp == null) {
      throw Exception('Appointment document ${doc.id} thiếu thông tin thời gian (startTime/endTime/appointmentTime)');
    }
    
    return Appointment(
      id: doc.id,
      userId: data['userId'] ?? '',
      barberId: data['barberId'] ?? '',
      serviceName: data['serviceName'] ?? 'Không rõ dịch vụ',
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      startTime: startTimeStamp.toDate(),
      endTime: endTimeStamp.toDate(),
      status: data['status'] ?? 'Không rõ',
    );
  }
}
