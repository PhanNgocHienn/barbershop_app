// lib/screens/admin/admin_chat_detail_screen.dart

import 'dart:async';

import 'package:barbershop_app/models/chat_message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Màn hình chat chi tiết cho admin - chat với một user cụ thể
/// Sử dụng Firebase Realtime Database
class AdminChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String userId;
  final String userName;
  final String? userPhone;

  const AdminChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.userName,
    this.userPhone,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
  ).ref();
  String? _adminName;
  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Load thông tin admin
  Future<void> _loadAdminInfo() async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser != null) {
        final userDoc = await _database.child('users').child(adminUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.value as Map<dynamic, dynamic>?;
          setState(() {
            _adminName = data?['displayName'] ?? 'Admin';
          });
        } else {
          setState(() {
            _adminName = 'Admin';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi load admin info: $e');
      setState(() {
        _adminName = 'Admin';
      });
    }
  }

  /// Đánh dấu tin nhắn đã đọc khi admin xem
  Future<void> _markMessagesAsRead() async {
    try {
      // Lấy tất cả tin nhắn chưa đọc mà user gửi
      final unreadSnapshot = await _database
          .child('conversations')
          .child(widget.conversationId)
          .child('messages')
          .orderByChild('senderId')
          .equalTo(widget.userId)
          .get();

      if (!unreadSnapshot.exists) return;

      final updates = <String, dynamic>{};
      final data = unreadSnapshot.value as Map<dynamic, dynamic>;

      for (var key in data.keys) {
        final message = data[key] as Map<dynamic, dynamic>;
        if (message['read'] != true) {
          updates['conversations/${widget.conversationId}/messages/$key/read'] = true;
        }
      }

      if (updates.isNotEmpty) {
        // Cập nhật tất cả messages đã đọc
        await _database.update(updates);

        // Cập nhật unreadCount trong conversation
        await _database
            .child('conversations')
            .child(widget.conversationId)
            .update({
          'unreadCount': 0,
        });
      }
    } catch (e) {
      debugPrint('Lỗi đánh dấu đã đọc: $e');
    }
  }

  /// Gửi tin nhắn
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _adminName == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Thêm tin nhắn vào messages
      await _database
          .child('conversations')
          .child(widget.conversationId)
          .child('messages')
          .push()
          .set({
        'senderId': 'admin',
        'senderName': _adminName!,
        'text': messageText,
        'timestamp': timestamp,
        'read': false,
      });

      // Cập nhật conversation với tin nhắn cuối
      await _database
          .child('conversations')
          .child(widget.conversationId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': 'admin',
        'unreadCount': 0, // Admin gửi thì reset unread của admin
      });

      // Scroll xuống tin nhắn mới
      _scrollToBottom();
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
        );
      }
    }
  }

  /// Scroll xuống cuối danh sách tin nhắn
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            if (widget.userPhone != null)
              Text(
                widget.userPhone!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _database
                  .child('conversations')
                  .child(widget.conversationId)
                  .child('messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Đánh dấu đã đọc khi có tin nhắn mới
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                if (data == null || data.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = data.entries
                    .map((entry) => ChatMessage.fromMap(
                          entry.key.toString(),
                          entry.value as Map<dynamic, dynamic>,
                        ))
                    .toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdmin = message.senderId == 'admin';

                    return _buildMessageBubble(message, isAdmin);
                  },
                );
              },
            ),
          ),

          // Thanh nhập tin nhắn
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.teal),
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.teal.withOpacity(0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị một tin nhắn
  Widget _buildMessageBubble(ChatMessage message, bool isAdmin) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final messageDate = message.dateTime;
    final now = DateTime.now();

    String timeStr = timeFormat.format(messageDate);
    if (!isSameDay(now, messageDate)) {
      timeStr = '${dateFormat.format(messageDate)} $timeStr';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.teal : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAdmin)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  if (!isAdmin) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isAdmin ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isAdmin
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isAdmin && message.read) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal[300],
              child: const Icon(Icons.admin_panel_settings,
                  size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Kiểm tra 2 ngày có cùng ngày không
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

