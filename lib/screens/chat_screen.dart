import 'package:flutter/material.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    ChatModel? chat = await _chatService.getChatById(widget.chatId);
    if (mounted) {
      setState(() {
        _chat = chat;
        _isLoading = false;
      });

      // Mark messages as read
      if (chat != null) {
        await _chatService.markMessagesAsRead(
          widget.chatId,
          _authService.currentUser!.uid,
        );
      }
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

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
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
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  );
                }

                List<MessageModel> messages = snapshot.data!;

                // Scroll to bottom when messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                String? lastDate;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    bool isSent = message.senderId == currentUserId;

                    // Check if we need to show date separator
                    String currentDate = TimeUtils.formatDate(message.timestamp);
                    bool showDateSeparator = lastDate != currentDate;
                    lastDate = currentDate;

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
                                  gradient: isSent
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: isSent ? null : Colors.white,
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
                    gradient: AppTheme.primaryGradient,
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

