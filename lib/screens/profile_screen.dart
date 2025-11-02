// lib/screens/profile_screen.dart

import 'package:barbershop_app/screens/change_password_screen.dart';
import 'package:barbershop_app/screens/edit_profile_screen.dart';
import 'package:barbershop_app/screens/chat_screen.dart';
import 'package:barbershop_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool get isEmailPasswordUser {
    if (currentUser == null) return false;
    return currentUser!.providerData.any(
      (userInfo) => userInfo.providerId == 'password',
    );
  }

  void _navigateToEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              currentUser?.displayName ?? 'Người dùng mới',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currentUser?.email ??
                  currentUser?.phoneNumber ??
                  'Không có thông tin liên hệ',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ProfileMenuItem(
              icon: Icons.edit_outlined,
              title: 'Chỉnh sửa hồ sơ',
              onTap: _navigateToEditProfile,
            ),
            if (isEmailPasswordUser)
              ProfileMenuItem(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ChangePasswordScreen(),
                  ),
                ),
              ),
            ProfileMenuItem(
              icon: Icons.chat_bubble_outline,
              title: 'Chat với Admin',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const ChatScreen(),
                ),
              ),
            ),
            ProfileMenuItem(
              icon: Icons.logout,
              title: 'Đăng xuất',
              textColor: Colors.red,
              onTap: () => AuthService().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
