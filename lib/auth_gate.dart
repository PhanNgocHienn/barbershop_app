// lib/auth_gate.dart

import 'package:barbershop_app/screens/auth_screen.dart';
import 'package:barbershop_app/screens/main_screen.dart'; // THAY ĐỔI IMPORT TẠI ĐÂY
import 'package:barbershop_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Nếu đã đăng nhập, chuyển đến MainScreen
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Nếu chưa, hiển thị màn hình đăng nhập
        return const AuthScreen();
      },
    );
  }
}
