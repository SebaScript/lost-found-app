import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createOrGetChat({
    required String postId,
    required String postTitle,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      String chatId1 = '${postId}_${senderId}_$receiverId';
      String chatId2 = '${postId}_${receiverId}_$senderId';

      DocumentSnapshot snapshot1 =
          await _firestore.collection('chats').doc(chatId1).get();
      if (snapshot1.exists) {
        return chatId1;
      }

      DocumentSnapshot snapshot2 =
          await _firestore.collection('chats').doc(chatId2).get();
      if (snapshot2.exists) {
        return chatId2;
      }

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

      await _firestore.collection('chats').doc(chatId1).set(newChat.toJson());
      return chatId1;
    } catch (e) {
      print('Error creating/getting chat: $e');
      throw 'Error al crear el chat';
    }
  }

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

      await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toJson());

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      });

      DocumentSnapshot chatSnapshot =
          await _firestore.collection('chats').doc(chatId).get();
      if (chatSnapshot.exists) {
        Map<String, dynamic> chatData =
            chatSnapshot.data() as Map<String, dynamic>;
        String postId = chatData['postId'];
        await _firestore.collection('posts').doc(postId).update({
          'messageCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      throw 'Error al enviar el mensaje';
    }
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .asyncMap((senderSnapshot) async {
      QuerySnapshot receiverSnapshot = await _firestore
          .collection('chats')
          .where('receiverId', isEqualTo: userId)
          .get();

      List<ChatModel> chats = [];

      for (var doc in senderSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        chats.add(ChatModel.fromJson(data));
      }

      for (var doc in receiverSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        chats.add(ChatModel.fromJson(data));
      }

      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      List<MessageModel> messages = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        messages.add(MessageModel.fromJson(data));
      }

      return messages;
    });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('chats').doc(chatId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
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
