// ================ admin_users_screen.dart ================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Hằng số màu
const Color _primaryColor = Color(0xFF00796B); // Teal[700]
const Color _scaffoldBgColor = Color(0xFFF5F5F5); // Colors.grey[100]

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có người dùng.'));
          }
          final docs = snapshot.data!.docs;

          // Thay ListView.separated bằng ListView.builder với Card
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final displayName = data['displayName'] ?? 'Không tên';
              final email = data['email'] ?? '';
              final enabled = (data['enabled'] as bool?) ?? true;
              final isAdmin = (data['isAdmin'] as bool?) ?? false;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: enabled ? Colors.white : Colors.grey.shade300,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    foregroundColor: _primaryColor,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: enabled
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Admin'),
                          backgroundColor: Colors.orange.shade100,
                          labelStyle: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(email.isEmpty ? doc.id : email),
                  // Thay 4 IconButton bằng 1 PopupMenuButton
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggleEnabled') {
                        _toggleEnabled(doc.id, !enabled);
                      } else if (value == 'toggleAdmin') {
                        _toggleAdmin(doc.id, !isAdmin);
                      } else if (value == 'edit') {
                        _openEditDialog(context, doc.id, data);
                      } else if (value == 'delete') {
                        _deleteUserDoc(context, doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggleEnabled',
                        child: Text(enabled ? 'Vô hiệu hóa' : 'Kích hoạt'),
                      ),
                      PopupMenuItem(
                        value: 'toggleAdmin',
                        child: Text(
                          isAdmin ? 'Bỏ quyền admin' : 'Cấp quyền admin',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Sửa thông tin'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Xóa (Doc)',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Logic functions (giữ nguyên)
  Future<void> _toggleEnabled(String userId, bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'enabled': value,
    });
  }

  Future<void> _toggleAdmin(String userId, bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isAdmin': value,
    });
  }

  void _openEditDialog(
    BuildContext context,
    String userId,
    Map<String, dynamic> initial,
  ) {
    final nameController = TextEditingController(
      text: initial['displayName'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa thông tin người dùng'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Tên hiển thị',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
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
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({
                    'displayName': nameController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserDoc(BuildContext context, String userId) async {
    // ... (Logic giữ nguyên)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa người dùng (Firestore doc)'),
        content: const Text(
          'Chỉ xóa document trong Firestore, không xóa tài khoản Auth.',
        ),
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
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa document user.')));
      }
    }
  }
}
