// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import 'home_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Dùng PageStorage để lưu trạng thái từng màn hình (VD: cuộn, tab con,...)
  final PageStorageBucket _bucket = PageStorageBucket();

  // Các màn hình chính
  final List<Widget> _screens = const [
    HomeScreen(key: PageStorageKey('HomeScreen')),
    AppointmentsScreen(key: PageStorageKey('AppointmentsScreen')),
    ProfileScreen(key: PageStorageKey('ProfileScreen')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: _bucket, child: _screens[_selectedIndex]),
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Theme.of(context).primaryColor,
        color: Colors.white,
        activeColor: Colors.amberAccent,
        style: TabStyle.reactCircle,
        items: const [
          TabItem(icon: Icons.home, title: 'Trang chủ'),
          TabItem(icon: Icons.calendar_today, title: 'Lịch hẹn'),
          TabItem(icon: Icons.person, title: 'Hồ sơ'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
