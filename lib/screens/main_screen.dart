// lib/screens/main_screen.dart

import 'package:barbershop_app/screens/appointments_screen.dart';
import 'package:barbershop_app/screens/home_screen.dart';
import 'package:barbershop_app/screens/profile_screen.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Biến để theo dõi trang đang được chọn, mặc định là trang chủ (index 0)
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với từng mục trên thanh điều hướng
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  // Hàm được gọi khi người dùng nhấn vào một mục
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị màn hình tương ứng với mục đã chọn
      body: _screens.elementAt(_selectedIndex),

      // Thanh điều hướng ở dưới đáy màn hình
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Theme.of(context).primaryColor,
        style: TabStyle.reactCircle, // Kiểu hiệu ứng "nhảy lên" khi nhấn
        items: const [
          TabItem(icon: Icons.home, title: 'Trang chủ'),
          TabItem(icon: Icons.calendar_today, title: 'Lịch hẹn'),
          TabItem(icon: Icons.person, title: 'Hồ sơ'),
        ],
        initialActiveIndex: _selectedIndex, // Mục được kích hoạt ban đầu
        onTap: _onItemTapped, // Hàm xử lý sự kiện nhấn
      ),
    );
  }
}
