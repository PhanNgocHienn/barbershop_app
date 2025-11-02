// lib/models/chat_message_model.dart

/// Model cho một tin nhắn trong chat
/// Sử dụng với Firebase Realtime Database
class ChatMessage {
  final String id;
  final String senderId; // ID của người gửi (userId hoặc 'admin')
  final String senderName; // Tên người gửi
  final String text; // Nội dung tin nhắn
  final int timestamp; // Thời gian gửi (Unix timestamp in milliseconds)
  final bool read; // Đã đọc chưa

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  /// Tạo ChatMessage từ Realtime Database snapshot
  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Người dùng',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      read: data['read'] ?? false,
    );
  }

  /// Chuyển đổi thành Map để lưu vào Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'read': read,
    };
  }

  /// Chuyển timestamp thành DateTime
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

/// Model cho một conversation (cuộc trò chuyện)
/// Sử dụng với Firebase Realtime Database
class Conversation {
  final String id;
  final String userId; // ID của user trong conversation
  final String userName; // Tên của user
  final String? userPhone; // Số điện thoại của user
  final String lastMessage; // Tin nhắn cuối cùng
  final int lastMessageTime; // Thời gian tin nhắn cuối (Unix timestamp in milliseconds)
  final int unreadCount; // Số tin nhắn chưa đọc (từ phía admin)
  final String lastMessageSenderId; // ID người gửi tin nhắn cuối

  Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.lastMessageSenderId,
  });

  /// Tạo Conversation từ Realtime Database snapshot
  factory Conversation.fromMap(String id, Map<dynamic, dynamic> data) {
    return Conversation(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Người dùng',
      userPhone: data['userPhone'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] ?? DateTime.now().millisecondsSinceEpoch,
      unreadCount: (data['unreadCount'] ?? 0) as int,
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
    );
  }

  /// Chuyển đổi thành Map để lưu vào Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      if (userPhone != null) 'userPhone': userPhone,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  /// Chuyển timestamp thành DateTime
  DateTime get lastMessageDateTime => DateTime.fromMillisecondsSinceEpoch(lastMessageTime);
}

