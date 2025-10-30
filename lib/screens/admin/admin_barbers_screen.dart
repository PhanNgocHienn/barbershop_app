import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/services/barber_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF00796B);
const Color _scaffoldBgColor = Color(0xFFF5F5F5);

class AdminBarbersScreen extends StatelessWidget {
  const AdminBarbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBarberDialog(context),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: BarberService().barbersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có thợ cắt tóc nào.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final barber = Barber.fromMap(data, id: doc.id);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading:
                      barber.avatarUrl != null && barber.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(barber.avatarUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    barber.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    barber.specialty,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: _primaryColor),
                        onPressed: () => _openBarberDialog(
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
                        onPressed: () => _deleteBarber(context, doc.id),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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

  void _openBarberDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    final nameController = TextEditingController(text: initial?['name'] ?? '');
    final specialtyController = TextEditingController(
      text: initial?['specialty'] ?? '',
    );
    final descController = TextEditingController(
      text: initial?['description'] ?? '',
    );
    final avatarController = TextEditingController(
      text: initial?['avatarUrl'] ?? '',
    );
    final imageController = TextEditingController(
      text: initial?['imageUrl'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          bool isSaving = false;
          return AlertDialog(
            scrollable: true,
            title: Text(
              docId == null ? 'Thêm thợ cắt tóc' : 'Sửa thông tin thợ',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(controller: nameController, label: 'Họ và tên'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: specialtyController,
                  label: 'Chuyên môn (VD: Cắt tóc nam, Uốn, Nhuộm...)',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: descController,
                  label: 'Mô tả thêm về kinh nghiệm, kỹ năng...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: avatarController,
                  label: 'URL ảnh đại diện',
                ),
                if (avatarController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(60),
                        image: avatarController.text.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarController.text),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                _buildTextField(
                  controller: imageController,
                  label: 'URL ảnh bìa',
                ),
                if (imageController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: imageController.text.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageController.text),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              StatefulBuilder(
                builder: (context2, setState2) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          try {
                            setState2(() => isSaving = true);
                            final data = {
                              'name': nameController.text.trim(),
                              'specialty': specialtyController.text.trim(),
                              'description': descController.text.trim(),
                              'imageUrl': imageController.text.trim(),
                              'avatarUrl': avatarController.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (docId == null) {
                              final ref = await BarberService().addBarber(data);
                              print('[Admin] Added barber id=${ref.id}');
                            } else {
                              await BarberService().updateBarber(docId, data);
                              print('[Admin] Updated barber id=$docId');
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    docId == null
                                        ? 'Đã thêm thợ mới thành công'
                                        : 'Đã cập nhật thông tin thành công',
                                  ),
                                ),
                              );
                            }
                          } catch (e, st) {
                            print('[Admin] add/update barber error: $e');
                            print(st);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Có lỗi xảy ra: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState2(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBarber(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa thợ này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BarberService().deleteBarber(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thợ thành công')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
