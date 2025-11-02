// lib/screens/admin/admin_chat_list_screen.dart

import 'package:barbershop_app/models/chat_message_model.dart';
import 'package:barbershop_app/screens/admin/admin_chat_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
    ).ref();

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: _database
            .child('conversations')
            .orderByChild('lastMessageTime')
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
                'Chưa có cuộc trò chuyện nào',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có cuộc trò chuyện nào',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final conversations = data.entries
              .map((entry) => Conversation.fromMap(
                    entry.key.toString(),
                    entry.value as Map<dynamic, dynamic>,
                  ))
              .toList()
            ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(context, conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation) {
    final hasUnread = conversation.unreadCount > 0;
    final timeFormat = _formatTime(conversation.lastMessageDateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: hasUnread ? 3 : 1,
      color: hasUnread ? Colors.blue[50] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.person, size: 28, color: Colors.white),
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          conversation.userName,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              conversation.lastMessage.isEmpty
                  ? 'Chưa có tin nhắn'
                  : conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (conversation.userPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                '📞 ${conversation.userPhone}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeFormat,
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? Colors.blue : Colors.grey,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (conversation.lastMessageSenderId == conversation.userId)
              const Icon(
                Icons.reply,
                size: 16,
                color: Colors.orange,
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AdminChatDetailScreen(
                conversationId: conversation.id,
                userId: conversation.userId,
                userName: conversation.userName,
                userPhone: conversation.userPhone,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Cùng ngày - chỉ hiển thị giờ
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      // Trong tuần - hiển thị thứ
      return DateFormat('EEEE', 'vi').format(time);
    } else {
      // Lâu hơn - hiển thị ngày/tháng
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}

