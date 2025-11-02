// lib/auth_gate.dart

import 'package:barbershop_app/screens/auth_screen.dart';
import 'package:barbershop_app/screens/main_screen.dart';
import 'package:barbershop_app/screens/admin/admin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

        // Nếu đã đăng nhập, kiểm tra trạng thái và role
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userSnap.hasData) {
                return const AuthScreen();
              }

              final userData = userSnap.data?.data() as Map<String, dynamic>?;
              // Kiểm tra tài khoản có bị vô hiệu hóa không
              final bool isEnabled = userData?['enabled'] == true;
              if (!isEnabled) {
                // Tài khoản bị disabled - tự động đăng xuất
                AuthService().signOut();
                return const AuthScreen();
              }

              final bool isAdmin = userData?['isAdmin'] == true;
              
              if (isAdmin) return const AdminScreen();
              return const MainScreen();
            },
          );
        }

        // Nếu chưa, hiển thị màn hình đăng nhập
        return const AuthScreen();
      },
    );
  }
}
