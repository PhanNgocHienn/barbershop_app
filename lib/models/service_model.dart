// lib/models/service_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String name;
  final double price;
  final int duration;

  Service({required this.name, required this.price, required this.duration});

  // Factory constructor đã được cập nhật để an toàn hơn
  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    double parsedPrice = 0.0;
    var priceData = data['price']; // Lấy dữ liệu giá

    if (priceData is num) {
      // Nếu dữ liệu đã là dạng số (int hoặc double)
      parsedPrice = priceData.toDouble();
    } else if (priceData is String) {
      // Nếu dữ liệu là dạng chuỗi, cố gắng chuyển đổi nó
      parsedPrice = double.tryParse(priceData) ?? 0.0;
    }

    return Service(
      name: data['name'] ?? '',
      price: parsedPrice, // Sử dụng giá đã được xử lý an toàn
      duration: data['duration'] ?? 0,
    );
  }
}
