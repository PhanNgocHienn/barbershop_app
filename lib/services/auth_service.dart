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
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await docRef.get();

    if (!snap.exists) {
      // Tài khoản mới - set giá trị mặc định
      await docRef.set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'enabled': true,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Tài khoản đã tồn tại - chỉ cập nhật thông tin cơ bản, giữ nguyên quyền admin
      await docRef.update({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Tạo tài khoản admin mới
  Future<UserCredential> createAdminAccount(
    String email,
    String password,
  ) async {
    // 1. Tạo tài khoản trong Authentication
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Tạo document trong collection users với isAdmin = true
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCred.user!.uid)
        .set({
          'displayName': '',
          'email': email,
          'phoneNumber': '',
          'isAdmin': true,
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    return userCred;
  }
}
