// ================ admin_services_screen.dart ================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Hằng số màu
const Color _primaryColor = Color(0xFF00796B); // Teal[700]
const Color _scaffoldBgColor = Color(0xFFF5F5F5); // Colors.grey[100]

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openServiceDialog(context),
        backgroundColor: _primaryColor, // Thêm màu nền
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có dịch vụ.'));
          }
          final docs = snapshot.data!.docs;

          // Thay ListView.separated bằng ListView.builder với Card
          return ListView.builder(
            padding: const EdgeInsets.all(12), // Thêm padding
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final price = (data['price'] is num)
                  ? (data['price'] as num).toDouble()
                  : double.tryParse('${data['price']}') ?? 0.0;
              final duration = data['duration'] ?? 0;

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
                  // Thêm icon đầu dòng
                  leading: const CircleAvatar(
                    backgroundColor: _primaryColor,
                    child: Icon(Icons.design_services, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${price.toStringAsFixed(0)}đ • ${duration}p'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: _primaryColor),
                        onPressed: () => _openServiceDialog(
                          context,
                          docId: doc.id,
                          initial: data,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteService(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Hàm helper để tạo TextField đẹp hơn
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _openServiceDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    final nameController = TextEditingController(text: initial?['name'] ?? '');
    final priceController = TextEditingController(
      text: initial?['price']?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: initial?['duration']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(docId == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(controller: nameController, label: 'Tên dịch vụ'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: priceController,
                label: 'Giá (VND)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: durationController,
                label: 'Thời lượng (phút)',
                keyboardType: TextInputType.number,
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
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () async {
              // ... (Logic giữ nguyên)
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final duration =
                  int.tryParse(durationController.text.trim()) ?? 0;
              final data = {
                'name': name,
                'price': price,
                'duration': duration,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (docId == null) {
                await FirebaseFirestore.instance.collection('services').add({
                  ...data,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await FirebaseFirestore.instance
                    .collection('services')
                    .doc(docId)
                    .update(data);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(BuildContext context, String docId) async {
    // ... (Logic giữ nguyên)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa dịch vụ'),
        content: const Text('Bạn có chắc muốn xóa dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Có'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa dịch vụ.')));
      }
    }
  }
}
