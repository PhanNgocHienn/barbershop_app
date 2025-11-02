import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Hằng số màu
const Color _primaryColor = Color(0xFF00796B); // Teal[700]
const Color _scaffoldBgColor = Color(0xFFF5F5F5); // Colors.grey[100]

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String? _statusFilter; // null = tất cả

  // Helper để lấy màu theo trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
      case 'reviewed':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build query: apply optional filter first, then orderBy.
    Query baseQuery = FirebaseFirestore.instance.collection('appointments');
    if (_statusFilter != null) {
      baseQuery = baseQuery.where('status', isEqualTo: _statusFilter);
    }
    baseQuery = baseQuery.orderBy('appointmentTime', descending: true);

    final stream = baseQuery.snapshots();

    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      body: Column(
        children: [
          // Làm đẹp thanh Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    isExpanded: true,
                    underline: Container(), // Bỏ gạch chân
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả')),
                      DropdownMenuItem(
                        value: 'scheduled',
                        child: Text('scheduled'),
                      ),
                      DropdownMenuItem(value: 'paid', child: Text('paid')),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('cancelled'),
                      ),
                      DropdownMenuItem(
                        value: 'reviewed',
                        child: Text('reviewed'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Show Firestore/indexing errors so admin can know what's wrong
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Lỗi khi tải lịch hẹn: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có lịch hẹn.'));
                }
                final docs = snapshot.data!.docs;
                // Thay ListView.separated bằng ListView.builder với Card
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userName = data['userName'] ?? '';
                    final userPhone = data['userPhone'] ?? '';
                    final serviceName = data['serviceName'] ?? '';
                    final price = (data['servicePrice'] is num)
                        ? (data['servicePrice'] as num).toDouble()
                        : double.tryParse('${data['servicePrice']}') ?? 0.0;
                    final status = data['status'] ?? 'unknown';
                    final ts = data['appointmentTime'] as Timestamp?;
                    final time = ts?.toDate();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            status,
                          ).withOpacity(0.1),
                          child: Icon(
                            Icons.calendar_month,
                            color: _getStatusColor(status),
                          ),
                        ),
                        title: Text(
                          '$userName • $userPhone',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${serviceName} • ${price.toStringAsFixed(0)}đ\n'
                          '${time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time) : 'N/A'}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(doc.id)
                                  .delete();
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(doc.id)
                                  .update({
                                    'status': value,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'scheduled',
                              child: Text('Đánh dấu scheduled'),
                            ),
                            const PopupMenuItem(
                              value: 'paid',
                              child: Text('Đánh dấu paid'),
                            ),
                            const PopupMenuItem(
                              value: 'completed',
                              child: Text('Đánh dấu completed'),
                            ),
                            const PopupMenuItem(
                              value: 'cancelled',
                              child: Text('Đánh dấu cancelled'),
                            ),
                            const PopupMenuItem(
                              value: 'reviewed',
                              child: Text('Đánh dấu reviewed'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Xóa lịch hẹn',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          child: Chip(
                            label: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getStatusColor(status),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
