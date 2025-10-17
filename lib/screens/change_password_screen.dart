// lib/screens/change_password_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      EasyLoading.show(status: 'Đang xử lý...');

      final oldPassword = _oldPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      try {
        // 1. Xác thực lại người dùng bằng mật khẩu cũ
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: oldPassword,
        );
        await currentUser!.reauthenticateWithCredential(credential);

        // 2. Nếu thành công, cập nhật mật khẩu mới
        await currentUser!.updatePassword(newPassword);

        EasyLoading.dismiss();
        EasyLoading.showSuccess('Đổi mật khẩu thành công!');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        // **THAY ĐỔI THÔNG BÁO LỖI TẠI ĐÂY**
        if (e.code == 'wrong-password') {
          // Hiển thị thông báo theo yêu cầu của bạn
          EasyLoading.showError('Nhập sai, yêu cầu nhập lại.');
        } else {
          EasyLoading.showError('Đã xảy ra lỗi: ${e.message}');
        }
      } catch (e) {
        EasyLoading.showError('Đã xảy ra lỗi không xác định.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _changePassword,
                child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
