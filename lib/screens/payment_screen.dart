// lib/screens/payment_screen.dart

import 'package:barbershop_app/models/appointment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatelessWidget {
  final Appointment appointment;

  const PaymentScreen({super.key, required this.appointment});

  // HÀM TẠO CHUỖI VIETQR
  String _generateVietQRString() {
    // --- THAY THẾ BẰNG THÔNG TIN CỦA BẠN ---
    const String bankId = "970416"; // Mã BIN của ngân hàng (Ví dụ: ACB)
    const String accountNumber = "123456789"; // Số tài khoản của bạn
    // ------------------------------------

    final int amount = appointment.servicePrice.toInt();
    // Tạo nội dung chuyển khoản ngắn gọn và duy nhất
    final String addInfo = "TT ${appointment.id.substring(0, 8)}";

    // API của VietQR để tạo mã QR động
    return "https://api.vietqr.io/v2/generate?accountNo=$accountNumber&accountName=CHỦ+TÀI+KHOẢN&acqId=$bankId&amount=$amount&addInfo=$addInfo&template=compact";
  }

  // Hàm cập nhật trạng thái sau khi người dùng xác nhận đã thanh toán
  Future<void> _confirmPayment(BuildContext context) async {
    EasyLoading.show(status: 'Đang xác nhận...');
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .update({'status': 'paid'}); // Cập nhật trạng thái thành 'paid'

      EasyLoading.showSuccess(
        'Xác nhận thành công!\nChủ tiệm sẽ kiểm tra sớm.',
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      EasyLoading.showError('Có lỗi xảy ra.');
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrData = _generateVietQRString();
    final String paymentContent = "TT ${appointment.id.substring(0, 8)}";

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VietQR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Text(
                'Quét mã để thanh toán',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sử dụng ứng dụng ngân hàng của bạn để quét mã QR.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Widget hiển thị mã QR
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                gapless: false,
                // embeddedImage: const AssetImage('assets/logo.png'), // Bỏ dòng này nếu không có logo
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Thông tin thanh toán
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                title: const Text('Nội dung chuyển khoản'),
                subtitle: Text(paymentContent),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentContent));
                    EasyLoading.showToast('Đã sao chép nội dung');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.price_change, color: Colors.indigo),
                title: const Text('Số tiền'),
                subtitle: Text('${appointment.servicePrice.toInt()} VNĐ'),
              ),
              const SizedBox(height: 32),

              // Nút xác nhận
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                ),
                onPressed: () => _confirmPayment(context),
                child: const Text(
                  'Tôi đã thanh toán',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lưu ý: Vui lòng nhấn nút này sau khi bạn đã hoàn tất chuyển khoản.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
