// lib/services/auth_service.dart

import 'package:barbershop_app/screens/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Hàm đăng nhập/đăng ký bằng Email ---
  Future<UserCredential?> signInOrRegisterWithEmail({
    required String email,
    required String password,
    required bool isLogin,
  }) async {
    try {
      if (isLogin) {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Lỗi FirebaseAuth: ${e.message}");
      return null;
    }
  }

  // --- Hàm gửi mã OTP đến số điện thoại ---
  Future<void> signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xác thực thất bại: ${e.code}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: ${e.message}')));
    }
  }

  // --- Hàm xác thực mã OTP ---
  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print("Lỗi xác thực OTP: $e");
      return false;
    }
  }

  // --- Hàm đăng xuất ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- Stream lắng nghe trạng thái đăng nhập ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
