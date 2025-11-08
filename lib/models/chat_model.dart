class ChatModel {
  final String? id;
  final String postId;
  final String postTitle;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;

  ChatModel({
    this.id,
    required this.postId,
    required this.postTitle,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      postId: json['postId'] ?? '',
      postTitle: json['postTitle'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'])
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'postTitle': postTitle,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  String getOtherUserName(String currentUserId) {
    return currentUserId == senderId ? receiverName : senderName;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == senderId ? receiverId : senderId;
  }
}

class MessageModel {
  final String? id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
}
