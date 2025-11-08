import 'package:firebase_database/firebase_database.dart';
import '../models/chat_model.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create or get existing chat
  Future<String> createOrGetChat({
    required String postId,
    required String postTitle,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      // Create a consistent chat ID based on post and users
      String chatId1 = '${postId}_${senderId}_$receiverId';
      String chatId2 = '${postId}_${receiverId}_$senderId';

      // Check if chat exists with either ID
      DataSnapshot snapshot1 = await _database.child('chats/$chatId1').get();
      if (snapshot1.exists) {
        return chatId1;
      }

      DataSnapshot snapshot2 = await _database.child('chats/$chatId2').get();
      if (snapshot2.exists) {
        return chatId2;
      }

      // Create new chat
      ChatModel newChat = ChatModel(
        id: chatId1,
        postId: postId,
        postTitle: postTitle,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _database.child('chats/$chatId1').set(newChat.toJson());
      return chatId1;
    } catch (e) {
      print('Error creating/getting chat: $e');
      throw 'Error al crear el chat';
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      MessageModel newMessage = MessageModel(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
      );

      // Add message
      DatabaseReference messageRef = _database.child('messages/$chatId').push();
      await messageRef.set(newMessage.toJson());

      // Update chat with last message
      await _database.child('chats/$chatId').update({
        'lastMessage': message,
        'lastMessageTime': ServerValue.timestamp,
        'unreadCount': ServerValue.increment(1),
      });

      // Increment message count in post
      DataSnapshot chatSnapshot = await _database.child('chats/$chatId').get();
      if (chatSnapshot.exists) {
        Map<String, dynamic> chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        String postId = chatData['postId'];
        await _database.child('posts/$postId/messageCount').set(ServerValue.increment(1));
      }
    } catch (e) {
      print('Error sending message: $e');
      throw 'Error al enviar el mensaje';
    }
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _database.child('chats').onValue.map((event) {
      List<ChatModel> chats = [];
      
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> chatsMap = event.snapshot.value as Map;
        chatsMap.forEach((key, value) {
          Map<String, dynamic> chatData = Map<String, dynamic>.from(value as Map);
          chatData['id'] = key;
          ChatModel chat = ChatModel.fromJson(chatData);
          
          // Include chats where user is sender or receiver
          if (chat.senderId == userId || chat.receiverId == userId) {
            chats.add(chat);
          }
        });
      }
      
      // Sort by last message time descending
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _database
        .child('messages/$chatId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      List<MessageModel> messages = [];
      
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map;
        messagesMap.forEach((key, value) {
          Map<String, dynamic> messageData = Map<String, dynamic>.from(value as Map);
          messageData['id'] = key;
          messages.add(MessageModel.fromJson(messageData));
        });
      }
      
      // Sort by timestamp ascending
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      DataSnapshot snapshot = await _database.child('messages/$chatId').get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> messagesMap = snapshot.value as Map;
        Map<String, dynamic> updates = {};
        
        messagesMap.forEach((key, value) {
          Map<String, dynamic> messageData = Map<String, dynamic>.from(value as Map);
          if (messageData['receiverId'] == userId && messageData['isRead'] == false) {
            updates['messages/$chatId/$key/isRead'] = true;
          }
        });
        
        if (updates.isNotEmpty) {
          await _database.update(updates);
        }
      }

      // Reset unread count
      await _database.child('chats/$chatId/unreadCount').set(0);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      DataSnapshot snapshot = await _database.child('chats/$chatId').get();
      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = chatId;
        return ChatModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }
}
