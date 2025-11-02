# Giải thích tính năng Chat Realtime giữa User và Admin
## Sử dụng Firebase Realtime Database

## 📦 Cài đặt

Trước tiên, bạn cần chạy lệnh để cài đặt package mới:

```bash
flutter pub get
```

Package `firebase_database: ^11.1.4` đã được thêm vào `pubspec.yaml`.

---

## 📊 Cấu trúc dữ liệu trong Realtime Database

Realtime Database sử dụng cấu trúc JSON tree. Cấu trúc dữ liệu như sau:

```
conversations/
  {conversationId}/
    userId: "user123"
    userName: "Nguyễn Văn A"
    userPhone: "0123456789" (optional)
    lastMessage: "Tin nhắn cuối cùng"
    lastMessageTime: 1699123456789 (Unix timestamp milliseconds)
    lastMessageSenderId: "admin" hoặc "user123"
    unreadCount: 0 (số tin chưa đọc của admin)
    userUnreadCount: 0 (số tin chưa đọc của user)
    messages/
      {messageId}/
        senderId: "admin" hoặc "user123"
        senderName: "Admin" hoặc "Tên user"
        text: "Nội dung tin nhắn"
        timestamp: 1699123456789
        read: false
```

---

## 📁 Các file và chức năng

### 1. `lib/models/chat_message_model.dart`

**Mục đích**: Định nghĩa model cho tin nhắn và conversation.

**Khác biệt với Firestore:**
- Sử dụng `Map<dynamic, dynamic>` thay vì `Map<String, dynamic>` (vì Realtime Database trả về dynamic)
- Sử dụng `int timestamp` (milliseconds) thay vì `Timestamp`
- `fromMap()` nhận `String id` và `Map<dynamic, dynamic>` (không có DocumentSnapshot)

**Các class:**

- **`ChatMessage`**: Model cho một tin nhắn
  - `fromMap(String id, Map)`: Parse từ Realtime Database snapshot
  - `toMap()`: Chuyển thành Map để lưu
  - `dateTime`: Getter chuyển timestamp thành DateTime

- **`Conversation`**: Model cho một cuộc trò chuyện
  - `fromMap(String id, Map)`: Parse từ Realtime Database snapshot
  - `toMap()`: Chuyển thành Map để lưu
  - `lastMessageDateTime`: Getter chuyển timestamp thành DateTime

---

### 2. `lib/screens/chat_screen.dart`

**Mục đích**: Màn hình chat cho user.

**Khác biệt với Firestore:**

```dart
// Firestore
final DatabaseReference _database = FirebaseFirestore.instance;

// Realtime Database  
final DatabaseReference _database = FirebaseDatabase.instance.ref();
```

**Các hàm chính:**

#### `_initializeConversation()`
- **Firestore**: Sử dụng `.collection('conversations').where(...).get()`
- **Realtime Database**: Sử dụng `.child('conversations').orderByChild('userId').equalTo(...).get()`
- Tìm conversation của user hiện tại, nếu chưa có thì tạo mới bằng `.push()`

#### `_sendMessage()`
- **Firestore**: `.collection().doc().collection('messages').add()`
- **Realtime Database**: `.child('conversations').child(conversationId).child('messages').push().set()`
- `push()` tự động tạo key unique cho message mới
- `set()` để ghi dữ liệu

#### `_markMessagesAsRead()`
- **Firestore**: Sử dụng batch update
- **Realtime Database**: Sử dụng `update()` với Map của paths
  ```dart
  updates['conversations/$_conversationId/messages/$key/read'] = true;
  await _database.update(updates); // Update nhiều paths cùng lúc
  ```

**StreamBuilder cho Realtime:**

```dart
StreamBuilder<DatabaseEvent>(
  stream: _database
      .child('conversations')
      .child(_conversationId!)
      .child('messages')
      .orderByChild('timestamp')  // Sắp xếp theo timestamp
      .onValue,  // Listen realtime changes
  builder: (context, snapshot) {
    // Xử lý DatabaseEvent
    final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
    // Parse messages...
  }
)
```

**Điểm quan trọng:**
- `onValue`: Listen tất cả thay đổi tại path
- `snapshot.value`: Lấy toàn bộ dữ liệu tại path đó
- Cần parse từ `Map<dynamic, dynamic>` thành List messages

---

### 3. `lib/screens/admin/admin_chat_list_screen.dart`

**Mục đích**: Danh sách conversations cho admin.

**StreamBuilder:**

```dart
StreamBuilder<DatabaseEvent>(
  stream: _database
      .child('conversations')
      .orderByChild('lastMessageTime')  // Sắp xếp theo thời gian
      .onValue,
  builder: (context, snapshot) {
    // Parse conversations và sort
    final conversations = data.entries
        .map((entry) => Conversation.fromMap(...))
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }
)
```

**Lưu ý:**
- Realtime Database sắp xếp ascending, cần sort lại descending trong code
- Hoặc có thể dùng `orderByChild('lastMessageTime').limitToLast(n)` để lấy n tin mới nhất

---

### 4. `lib/screens/admin/admin_chat_detail_screen.dart`

**Mục đích**: Màn hình chat chi tiết cho admin.

**Tương tự `chat_screen.dart`** nhưng:
- `senderId: 'admin'` khi admin gửi
- Màu teal cho tin nhắn admin
- Icon admin trong avatar

---

## 🔄 So sánh Firestore vs Realtime Database

| Tính năng | Firestore | Realtime Database |
|-----------|-----------|-------------------|
| **Cấu trúc** | Collections/Documents | JSON Tree |
| **Query** | `.where().orderBy()` | `.orderByChild().equalTo()` |
| **Realtime** | `.snapshots()` | `.onValue` hoặc `.onChildAdded` |
| **Data Type** | `Map<String, dynamic>` | `Map<dynamic, dynamic>` |
| **Timestamp** | `Timestamp` object | `int` (milliseconds) |
| **Update nhiều** | Batch write | `update()` với Map paths |
| **Auto ID** | `.add()` | `.push()` |

---

## 🔑 Các khái niệm quan trọng

### 1. **DatabaseReference**
- Đại diện cho một path trong Realtime Database
- `FirebaseDatabase.instance.ref()` - root reference
- `.child('path')` - đi sâu vào path
- `.push()` - tạo key tự động (như `-N123abc`)

### 2. **DatabaseEvent và DataSnapshot**
- `DatabaseEvent`: Event khi có thay đổi
- `snapshot`: Chứa dữ liệu tại thời điểm event
- `snapshot.value`: Lấy giá trị (có thể là Map, List, hoặc primitive)
- `snapshot.exists`: Kiểm tra path có tồn tại không

### 3. **Stream Listeners**
- `.onValue`: Listen tất cả thay đổi tại path (bao gồm cả children)
- `.onChildAdded`: Chỉ trigger khi có child mới được thêm
- `.onChildChanged`: Trigger khi child thay đổi
- `.onChildRemoved`: Trigger khi child bị xóa

### 4. **Query Methods**
- `.orderByChild('field')`: Sắp xếp theo field
- `.equalTo(value)`: Filter bằng giá trị
- `.limitToFirst(n)`: Lấy n đầu tiên
- `.limitToLast(n)`: Lấy n cuối cùng
- Có thể kết hợp: `.orderByChild().equalTo().limitToFirst()`

### 5. **Update Operations**
- `set()`: Ghi đè toàn bộ data tại path
- `update()`: Update nhiều paths cùng lúc (Map<String, dynamic>)
- `push().set()`: Tạo node mới với auto-generated key
- `remove()`: Xóa node

---

## 🚀 Luồng hoạt động

### User gửi tin nhắn:
1. User nhập tin nhắn và nhấn Send
2. `_sendMessage()` được gọi
3. Tạo message mới: `messages.push().set({...})`
4. Update conversation: `conversations/{id}.update({lastMessage: ...})`
5. StreamBuilder tự động cập nhật UI (realtime qua `onValue`)

### Admin nhận và phản hồi:
1. Admin mở tab Chat → `onValue` stream tự động load conversations
2. Click vào conversation → mở `AdminChatDetailScreen`
3. `_markMessagesAsRead()` tự động đánh dấu đã đọc
4. Admin gửi phản hồi
5. User nhận tin nhắn realtime qua StreamBuilder

---

## 📝 Lưu ý kỹ thuật

1. **Indexing**: Realtime Database cần index cho query phức tạp
   - Ví dụ: `orderByChild('userId').equalTo(...)` cần index
   - Firebase Console sẽ tự động gợi ý tạo index

2. **Security Rules**: Cần cấu hình trong Firebase Console
   ```json
   {
     "rules": {
       "conversations": {
         "$conversationId": {
           ".read": "auth != null && ($conversationId.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('isAdmin').val() == true)",
           ".write": "auth != null && ($conversationId.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('isAdmin').val() == true)"
         }
       }
     }
   }
   ```

3. **Offline Support**: Realtime Database tự động cache và sync offline

4. **Performance**: 
   - Sử dụng `.limitToFirst/Last()` để giới hạn số lượng data
   - Tránh load toàn bộ messages nếu có nhiều (có thể paginate)

5. **Data Parsing**: Luôn kiểm tra null và type casting cẩn thận
   ```dart
   final data = snapshot.value as Map<dynamic, dynamic>?;
   if (data == null) return; // Handle null case
   ```

---

## 🎯 Ưu điểm của Realtime Database

1. **Realtime tốt hơn**: Cập nhật nhanh hơn Firestore cho realtime chat
2. **Đơn giản hơn**: Không cần subcollection, chỉ cần nested paths
3. **Offline mặc định**: Tự động cache và sync
4. **Chi phí**: Có thể rẻ hơn cho use case đơn giản

## ⚠️ Nhược điểm

1. **Query hạn chế**: Không mạnh bằng Firestore
2. **Cấu trúc phẳng**: Khó scale với dữ liệu phức tạp
3. **Security Rules**: Phức tạp hơn Firestore rules

---

## 📖 Tài liệu tham khảo

- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)
- [Flutter Firebase Database Package](https://pub.dev/packages/firebase_database)

