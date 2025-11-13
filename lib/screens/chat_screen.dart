import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../utils/app_theme.dart';
import '../utils/time_utils.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _authService = AuthService();

  ChatModel? _chat;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _newMessageSubscription;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _newMessageSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 50) {
      if (!_isLoadingMore && _hasMore) {
        _loadOlderMessages();
      }
    }
  }

  Future<void> _loadChatData() async {
    ChatModel? chat = await _chatService.getChatById(widget.chatId);
    if (mounted) {
      setState(() {
        _chat = chat;
      });

      await _loadInitialMessages();

      if (chat != null) {
        await _chatService.markMessagesAsRead(
          widget.chatId,
          _authService.currentUser!.uid,
        );
      }
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<MessageModel> messages = await _chatService.getMessagesPaginated(
        widget.chatId,
        limit: 50,
      );

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (messages.isNotEmpty) {
        _lastDocument = await _getMessageDocument(messages.first);
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMore = messages.length >= 50;
      });

      _listenForNewMessages();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error loading initial messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<MessageModel> olderMessages = await _chatService.getMessagesPaginated(
        widget.chatId,
        limit: 50,
        startBefore: _lastDocument,
      );

      if (olderMessages.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      double scrollPosition = _scrollController.position.pixels;
      double maxScrollExtent = _scrollController.position.maxScrollExtent;

      if (olderMessages.isNotEmpty) {
        _lastDocument = await _getMessageDocument(olderMessages.first);
      }

      setState(() {
        _messages.insertAll(0, olderMessages);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoadingMore = false;
        _hasMore = olderMessages.length >= 50;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          double newMaxScrollExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(scrollPosition + (newMaxScrollExtent - maxScrollExtent));
        }
      });
    } catch (e) {
      print('Error loading older messages: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _listenForNewMessages() {
    _newMessageSubscription?.cancel();
    
    DateTime cutoffTime = _messages.isNotEmpty 
        ? _messages.last.timestamp 
        : DateTime.now().subtract(const Duration(seconds: 1));
    
    _newMessageSubscription = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          data['id'] = change.doc.id;
          MessageModel newMessage = MessageModel.fromJson(data);
          
          bool alreadyExists = _messages.any((m) => m.id == newMessage.id);
          
          if (!alreadyExists) {
            setState(() {
              _messages.add(newMessage);
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            _chatService.markMessagesAsRead(
              widget.chatId,
              _authService.currentUser!.uid,
            );
          }
        }
      }
    });
  }

  Future<DocumentSnapshot?> _getMessageDocument(MessageModel message) async {
    try {
      return await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatId)
          .collection('messages')
          .doc(message.id)
          .get();
    } catch (e) {
      print('Error getting message document: $e');
      return null;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chat == null) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    try {
      String currentUserId = _authService.currentUser!.uid;
      String receiverId = _chat!.getOtherUserId(currentUserId);

      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: _isLoading || _chat == null
            ? const Text('Chat')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _chat!.getOtherUserName(currentUserId ?? ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Sobre: ${_chat!.postTitle}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay mensajes aún',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingMore && index == 0) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          int messageIndex = _isLoadingMore ? index - 1 : index;
                          MessageModel message = _messages[messageIndex];
                          bool isSent = message.senderId == currentUserId;

                          String? lastDate;
                          if (messageIndex > 0) {
                            lastDate = TimeUtils.formatDate(
                                _messages[messageIndex - 1].timestamp);
                          }

                          String currentDate =
                              TimeUtils.formatDate(message.timestamp);
                          bool showDateSeparator = lastDate != currentDate;

                    return Column(
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              currentDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isSent
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isSent
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSent
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isSent ? 16 : 4),
                                    bottomRight: Radius.circular(isSent ? 4 : 16),
                                  ),
                                  border: isSent
                                      ? null
                                      : Border.all(color: AppTheme.borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSent
                                          ? AppTheme.primaryColor.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.message,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSent
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  TimeUtils.formatTime(message.timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgTertiary,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppTheme.borderLight, width: 2),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(22),
                      child: const Center(
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

