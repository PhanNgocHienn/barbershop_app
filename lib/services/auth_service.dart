// lib/services/auth_service.dart

import 'package:barbershop_app/screens/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      UserCredential cred;
      if (isLogin) {
        cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // Ensure user document exists/updated
      await _ensureUserDocument(cred.user);
      return cred;
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
          final cred = await _auth.signInWithCredential(credential);
          await _ensureUserDocument(cred.user);
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
      final cred = await _auth.signInWithCredential(credential);
      await _ensureUserDocument(cred.user);
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

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final docRef = users.doc(user.uid);
    final snap = await docRef.get();
    final now = FieldValue.serverTimestamp();
    final data = {
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'enabled': true,
      'isAdmin': false,
      'updatedAt': now,
    };
    if (!snap.exists) {
      await docRef.set({
        ...data,
        'createdAt': now,
      }, SetOptions(merge: true));
    } else {
      await docRef.set(data, SetOptions(merge: true));
    }
  }
}
