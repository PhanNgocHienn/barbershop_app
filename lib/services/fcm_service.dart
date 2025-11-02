// lib/services/fcm_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service quản lý Firebase Cloud Messaging (FCM)
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Khởi tạo FCM và lấy token
  static Future<void> initialize() async {
    try {
      // Request permission cho notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
        
        // Lấy FCM token
        await _saveTokenToFirestore();
        
        // Lắng nghe khi token được refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _saveTokenToFirestore(newToken);
        });
      } else {
        debugPrint('❌ User declined or has not accepted notification permission');
      }

      // Xử lý notification khi app ở foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý notification khi user click vào notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Kiểm tra notification khi app được mở từ trạng thái terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Lưu FCM token vào Firestore
  static Future<void> _saveTokenToFirestore([String? token]) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Lấy token nếu chưa có
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('⚠️ FCM Token is null');
        return;
      }

      // Lấy user data để kiểm tra isAdmin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final isAdmin = userData?['isAdmin'] == true;

      // Lưu token vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ FCM Token saved to Firestore: $fcmToken (Admin: $isAdmin)');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Xử lý notification khi app ở foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    
    // Có thể hiển thị local notification ở đây nếu cần
  }

  /// Xử lý khi user click vào notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 Notification opened: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    
    // Có thể navigate đến màn hình chi tiết booking ở đây
    if (message.data['type'] == 'new_booking') {
      final appointmentId = message.data['appointmentId'];
      debugPrint('Navigate to booking: $appointmentId');
      // TODO: Navigate to booking details
    }
  }

  /// Lấy tất cả FCM tokens của admin
  static Future<List<String>> getAdminTokens() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .where('enabled', isEqualTo: true)
          .get();

      final tokens = <String>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      debugPrint('📋 Found ${tokens.length} admin FCM tokens');
      return tokens;
    } catch (e) {
      debugPrint('❌ Error getting admin tokens: $e');
      return [];
    }
  }

  /// Gửi notification đến tất cả admin khi có booking mới
  /// ⚠️ DEPRECATED: Legacy API sẽ ngừng hoạt động sau 6/20/2024
  /// Khuyến nghị: Sử dụng Firebase Cloud Functions thay vì method này
  /// Xem FCM_MIGRATION_GUIDE.md để biết cách migrate
  @Deprecated('Use Cloud Functions instead. Legacy API will be removed 6/20/2024')
  static Future<bool> sendBookingNotificationToAdmins({
    required String userName,
    required String userPhone,
    required String serviceName,
    required String appointmentTime,
    required String appointmentId,
  }) async {
    try {
      // Lấy admin tokens
      final adminTokens = await getAdminTokens();
      if (adminTokens.isEmpty) {
        debugPrint('⚠️ No admin tokens found');
        return false;
      }

      // Lấy Firebase Server Key từ Firestore hoặc cấu hình
      // TODO: Lưu server key vào Firestore config hoặc environment
      // Tạm thời bạn cần thay YOUR_SERVER_KEY bằng Server Key từ Firebase Console
      const serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Lấy từ Firebase Console → Project Settings → Cloud Messaging → Server Key
      
      if (serverKey == 'YOUR_FIREBASE_SERVER_KEY') {
        debugPrint('❌ Firebase Server Key chưa được cấu hình');
        return false;
      }

      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      final body = {
        'registration_ids': adminTokens,
        'notification': {
          'title': '📅 Đặt lịch mới',
          'body': '$userName đã đặt lịch $serviceName\nThời gian: $appointmentTime',
          'sound': 'default',
        },
        'data': {
          'type': 'new_booking',
          'appointmentId': appointmentId,
          'userName': userName,
          'userPhone': userPhone,
          'serviceName': serviceName,
          'appointmentTime': appointmentTime,
        },
        'priority': 'high',
      };

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ FCM notification sent successfully');
        debugPrint('Success: ${result['success']}, Failure: ${result['failure']}');
        return true;
      } else {
        debugPrint('❌ FCM notification failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
      return false;
    }
  }
}

