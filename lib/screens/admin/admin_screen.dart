// ================ admin_screen.dart ================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_services_screen.dart';
import 'admin_users_screen.dart';
import 'admin_bookings_screen.dart';

// Thêm các hằng số màu để dễ quản lý
const Color _primaryColor = Color(0xFF00796B); // Teal[700]
const Color _scaffoldBgColor = Color(0xFFF5F5F5); // Colors.grey[100]

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _scaffoldBgColor, // Sử dụng hằng số
        appBar: AppBar(
          backgroundColor: _primaryColor, // Sử dụng hằng số
          elevation: 5,
          title: const Text(
            'Bảng điều khiển Admin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
              color: Colors.white, // Đảm bảo title màu trắng
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Đăng xuất',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.teal[100], // Làm màu nhạt hơn chút
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Services', icon: Icon(Icons.miscellaneous_services)),
              Tab(text: 'Users', icon: Icon(Icons.group)),
              Tab(text: 'Bookings', icon: Icon(Icons.calendar_today)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminServicesScreen(),
            AdminUsersScreen(),
            AdminBookingsScreen(),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
              // AuthGate sẽ tự động chuyển về màn hình đăng nhập
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
