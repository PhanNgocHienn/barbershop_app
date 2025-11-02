import 'package:barbershop_app/models/appointment_model.dart';
import 'package:barbershop_app/screens/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barbershop_app/screens/barber_details_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy lịch hẹn thành công.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy lịch hẹn: $e')));
      }
    }
  }

  void _showCancelConfirmationDialog(String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này không?'),
        actions: [
          TextButton(
            child: const Text('Không'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Có, hủy lịch'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelAppointment(appointmentId);
            },
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Appointment appointment) {
    final reviewController = TextEditingController();
    double rating = 3.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Để lại đánh giá'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Text(
                        'Bạn đánh giá: ${rating.toInt()} sao',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: rating.round().toString(),
                        onChanged: (newRating) =>
                            setState(() => rating = newRating),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitReview(appointment, rating, reviewController.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Gửi đánh giá'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(
    Appointment appointment,
    double rating,
    String comment,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('barbers')
        .doc(appointment.barberId)
        .collection('reviews')
        .add({
          'rating': rating,
          'comment': comment,
          'userId': user.uid,
          'userName': user.displayName ?? 'Người dùng ẩn danh',
          'createdAt': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .update({'status': 'reviewed'});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
    }
  }

  Future<Map<String, String>> _getBarberDetails(String barberId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .get();
      if (doc.exists) {
        return {
          'name': doc.data()?['name'] ?? 'Không rõ',
          'imageUrl': doc.data()?['imageUrl'] ?? '',
        };
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin thợ: $e");
    }
    return {'name': 'Không rõ', 'imageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Không thể xác định người dùng.')),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Lịch hẹn của tôi'),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentsList(statusToShow: ['scheduled', 'paid']),
            _buildAppointmentsList(
              statusToShow: ['completed', 'cancelled', 'reviewed'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList({required List<String> statusToShow}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: statusToShow)
          .orderBy('appointmentTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có lịch hẹn nào.'));
        }

        final appointmentDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: appointmentDocs.length,
          itemBuilder: (context, index) {
            final appointment = Appointment.fromFirestore(
              appointmentDocs[index],
            );
            return FutureBuilder<Map<String, String>>(
              future: _getBarberDetails(appointment.barberId),
              builder: (context, barberSnapshot) {
                if (!barberSnapshot.hasData) {
                  return const ListTile(title: Text('Đang tải lịch hẹn...'));
                }
                final barberDetails = barberSnapshot.data!;

                return AppointmentCard(
                  appointment: appointment,
                  barberName: barberDetails['name']!,
                  barberImageUrl: barberDetails['imageUrl']!,
                  onCancel:
                      appointment.status == 'scheduled' ||
                          appointment.status == 'paid'
                      ? () => _showCancelConfirmationDialog(appointment.id)
                      : null,
                  onReview: appointment.status == 'completed'
                      ? () => _showReviewDialog(appointment)
                      : null,
                  onPay: appointment.status == 'scheduled'
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  PaymentScreen(appointment: appointment),
                            ),
                          );
                        }
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String barberName;
  final String barberImageUrl;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final VoidCallback? onPay;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.barberName,
    required this.barberImageUrl,
    this.onCancel,
    this.onReview,
    this.onPay,
  });

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData iconData;

    switch (appointment.status) {
      case 'scheduled':
        badgeColor = Colors.blue;
        statusText = 'Đã đặt';
        iconData = Icons.check_circle_outline;
        break;
      case 'paid':
        badgeColor = Colors.teal;
        statusText = 'Đã thanh toán';
        iconData = Icons.credit_card;
        break;
      case 'completed':
        badgeColor = Colors.green;
        statusText = 'Hoàn thành';
        iconData = Icons.check_circle;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        statusText = 'Đã hủy';
        iconData = Icons.cancel;
        break;
      case 'reviewed':
        badgeColor = Colors.orange;
        statusText = 'Đã đánh giá';
        iconData = Icons.star;
        break;
      default:
        badgeColor = Colors.grey;
        statusText = 'Không rõ';
        iconData = Icons.help_outline;
        break;
    }
    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 16),
      label: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: badgeColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: barberImageUrl.isNotEmpty
                      ? NetworkImage(barberImageUrl)
                      : null,
                  child: barberImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thợ cắt tóc: $barberName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.serviceName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy').format(appointment.startTime)}',
                    ),
                    Text(
                      'Giờ: ${DateFormat('HH:mm').format(appointment.startTime)}',
                    ),
                  ],
                ),
                Text(
                  '${appointment.servicePrice.toStringAsFixed(0)} VNĐ',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (onPay != null || onCancel != null || onReview != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onPay != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Thanh toán'),
                        onPressed: onPay,
                      ),
                    if (onCancel != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy lịch'),
                        onPressed: onCancel,
                      ),
                    if (onReview != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                        ),
                        icon: const Icon(Icons.star_border),
                        label: const Text('Đánh giá'),
                        onPressed: onReview,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
