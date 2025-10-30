// lib/screens/auth_screen.dart

import 'package:barbershop_app/screens/phone_auth_screen.dart';
import 'package:barbershop_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid != true) return;

    _formKey.currentState?.save();

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInOrRegisterWithEmail(
        email: _email.trim(),
        password: _password.trim(),
        isLogin: _isLogin,
      );

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? 'Email hoặc mật khẩu không đúng'
                  : 'Không thể tạo tài khoản. Email có thể đã được sử dụng.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Đã có lỗi xảy ra';

        switch (e.code) {
          case 'user-not-found':
            message = 'Không tìm thấy tài khoản với email này';
            break;
          case 'wrong-password':
            message = 'Mật khẩu không đúng';
            break;
          case 'email-already-in-use':
            message = 'Email này đã được sử dụng';
            break;
          case 'invalid-email':
            message = 'Email không hợp lệ';
            break;
          case 'weak-password':
            message = 'Mật khẩu quá yếu';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không xác định: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            key: const ValueKey('email'),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Vui lòng nhập một email hợp lệ.';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value ?? '',
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Địa chỉ Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            key: const ValueKey('password'),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự.';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value ?? '',
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 80,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _trySubmit,
                            child: Text(
                              _isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () =>
                                setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin
                                  ? 'Tạo tài khoản mới'
                                  : 'Tôi đã có tài khoản',
                            ),
                          ),

                          const Divider(height: 20),

                          TextButton.icon(
                            icon: const Icon(Icons.phone_android),
                            label: const Text('Đăng nhập với số điện thoại'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const PhoneAuthScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
