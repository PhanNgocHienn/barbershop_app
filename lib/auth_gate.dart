// lib/auth_gate.dart

import 'package:barbershop_app/screens/auth_screen.dart';
import 'package:barbershop_app/screens/main_screen.dart'; // THAY ĐỔI IMPORT TẠI ĐÂY
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

        // Nếu đã đăng nhập, kiểm tra role
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isAdmin = (userSnap.data?.data() as Map<String, dynamic>?)?['isAdmin'] == true;
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
