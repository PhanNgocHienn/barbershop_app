// lib/screens/chat_screen.dart

import 'dart:async';

import 'package:barbershop_app/models/chat_message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Màn hình chat cho user - chat với admin
/// Sử dụng Firebase Realtime Database
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
  ).ref();
  late String _currentUserId;
  String _currentUserName = 'Bạn';
  String? _conversationId;
  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Load user info và initialize conversation song song
      _loadUserInfo().then((_) {
        _initializeConversation();
      }).catchError((e) {
        debugPrint('Lỗi trong initState: $e');
        // Vẫn thử initialize conversation dù load user info lỗi
        _initializeConversation();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Load thông tin user để hiển thị tên
  Future<void> _loadUserInfo() async {
    try {
      final userDoc = await _database.child('users').child(_currentUserId).get();
      if (userDoc.exists && userDoc.value != null) {
        final data = userDoc.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            _currentUserName = data['displayName']?.toString() ?? 
                             data['email']?.toString().split('@')[0] ?? 
                             'Người dùng';
          });
          debugPrint('Loaded user name: $_currentUserName');
        }
      } else {
        // Nếu không có trong Realtime Database, dùng Firestore hoặc Auth
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          setState(() {
            _currentUserName = authUser.displayName ?? 
                             authUser.email?.split('@')[0] ?? 
                             'Người dùng';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi load user info: $e');
      // Fallback: dùng thông tin từ Auth
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        setState(() {
          _currentUserName = authUser.displayName ?? 
                           authUser.email?.split('@')[0] ?? 
                           'Người dùng';
        });
      }
    }
  }

  /// Khởi tạo hoặc lấy conversation ID
  Future<void> _initializeConversation() async {
    try {
      // Cách 1: Thử tìm conversation đã tồn tại (có thể cần index)
      // Với rules public, query có thể lỗi nếu thiếu index, nhưng vẫn thử
      try {
        final conversationsSnapshot = await _database
            .child('conversations')
            .orderByChild('userId')
            .equalTo(_currentUserId)
            .limitToFirst(1)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Query timeout');
              },
            );

        if (conversationsSnapshot.exists && conversationsSnapshot.value != null) {
          final value = conversationsSnapshot.value;
          if (value is Map && value.isNotEmpty) {
            setState(() {
              _conversationId = value.keys.first.toString();
            });
            debugPrint('✅ Tìm thấy conversation: $_conversationId');
            return;
          }
        }
      } catch (queryError) {
        // Nếu query lỗi (có thể do thiếu index hoặc permission), bỏ qua và tạo mới
        debugPrint('⚠️ Query conversation lỗi (bỏ qua và tạo mới): $queryError');
        // Tiếp tục với việc tạo conversation mới
      }

      // Cách 2: Tạo conversation mới nếu chưa có
      final newConversationRef = _database.child('conversations').push();
      final conversationKey = newConversationRef.key;
      
      if (conversationKey == null) {
        throw Exception('Không thể tạo conversation key');
      }

      // Tạo conversation data
      final conversationData = {
        'userId': _currentUserId,
        'userName': _currentUserName,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageSenderId': '',
        'unreadCount': 0,
        'userUnreadCount': 0,
      };

      // Thử set conversation với timeout
      await newConversationRef
          .set(conversationData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Set conversation timeout');
            },
          )
          .catchError((error) {
        debugPrint('❌ Lỗi khi set conversation: $error');
        throw error;
      });

      setState(() {
        _conversationId = conversationKey;
      });
      
      debugPrint('Đã tạo conversation mới: $_conversationId');
    } catch (e) {
      debugPrint('Lỗi khởi tạo conversation: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Current userId: $_currentUserId');
      
      if (mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lỗi khởi tạo chat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _initializeConversation();
              },
            ),
          ),
        );
      }
    }
  }

  /// Gửi tin nhắn
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversationId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Thêm tin nhắn vào messages
      await _database
          .child('conversations')
          .child(_conversationId!)
          .child('messages')
          .push()
          .set({
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'text': messageText,
        'timestamp': timestamp,
        'read': false,
      });

      // Cập nhật conversation với tin nhắn cuối
      await _database
          .child('conversations')
          .child(_conversationId!)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': _currentUserId,
        'userUnreadCount': 0, // User gửi thì reset unread của mình
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

  /// Đánh dấu tin nhắn đã đọc khi user xem
  Future<void> _markMessagesAsRead() async {
    if (_conversationId == null) return;

    try {
      // Lấy tất cả tin nhắn chưa đọc mà admin gửi
      final unreadSnapshot = await _database
          .child('conversations')
          .child(_conversationId!)
          .child('messages')
          .orderByChild('senderId')
          .equalTo('admin')
          .get();

      if (!unreadSnapshot.exists) return;

      final updates = <String, dynamic>{};
      final data = unreadSnapshot.value as Map<dynamic, dynamic>;
      
      for (var key in data.keys) {
        final message = data[key] as Map<dynamic, dynamic>;
        if (message['read'] != true) {
          updates['conversations/$_conversationId/messages/$key/read'] = true;
        }
      }

      if (updates.isNotEmpty) {
        // Cập nhật tất cả messages đã đọc
        await _database.update(updates);
        
        // Cập nhật userUnreadCount
        await _database
            .child('conversations')
            .child(_conversationId!)
            .update({'userUnreadCount': 0});
      }
    } catch (e) {
      debugPrint('Lỗi đánh dấu đã đọc: $e');
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
    if (_conversationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat với Admin'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo chat...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với Admin'),
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
                  .child(_conversationId!)
                  .child('messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Lỗi khi tải tin nhắn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
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
                if (data == null) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = <ChatMessage>[];
                for (var entry in data.entries) {
                  try {
                    final messageData = entry.value;
                    if (messageData is Map<dynamic, dynamic>) {
                      messages.add(ChatMessage.fromMap(
                        entry.key.toString(),
                        messageData,
                      ));
                    }
                  } catch (e) {
                    debugPrint('Lỗi parse message ${entry.key}: $e');
                  }
                }
                messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return const SizedBox.shrink();
                    }
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return _buildMessageBubble(message, isMe);
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
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
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
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
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
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.person, size: 18, color: Colors.white),
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

