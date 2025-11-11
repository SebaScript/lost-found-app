import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/chat_service.dart';
import '../utils/app_theme.dart';
import '../utils/time_utils.dart';
import 'chat_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  final _authService = AuthService();
  final _chatService = ChatService();
  
  PostModel? _post;
  UserModel? _postOwner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    try {
      PostModel? post = await _postService.getPostById(widget.postId);
      if (post != null) {
        UserModel? owner = await _authService.getUserData(post.userId);
        
        // Increment view count
        await _postService.incrementViewCount(widget.postId);

        if (mounted) {
          setState(() {
            _post = post;
            _postOwner = owner;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los detalles: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    if (_post == null || _postOwner == null) return;

    try {
      UserModel? currentUser = await _authService.getUserData(
        _authService.currentUser!.uid,
      );

      if (currentUser == null) return;

      String chatId = await _chatService.createOrGetChat(
        postId: _post!.id!,
        postTitle: _post!.title,
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        receiverId: _postOwner!.uid,
        receiverName: _postOwner!.displayName,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: chatId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar chat: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Detalle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Publicación no encontrada'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (_post!.imageUrl != null && _post!.imageUrl!.isNotEmpty)
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 300,
                              color: AppTheme.bgTertiary,
                              child: Image.network(
                                _post!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.bgTertiary,
                                    child: const Center(
                                      child: Icon(Icons.image,
                                          size: 50, color: AppTheme.textTertiary),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Type badge
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _post!.type == PostType.lost
                                      ? AppTheme.lostColor
                                      : AppTheme.foundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_post!.type == PostType.lost
                                              ? AppTheme.errorColor
                                              : AppTheme.successColor)
                                          .withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _post!.getTypeLabel().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: _post!.type == PostType.lost
                                        ? AppTheme.lostTextColor
                                        : AppTheme.foundTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              _post!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Meta info
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _post!.location,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  TimeUtils.getTimeAgo(_post!.createdAt),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Description section
                            const Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _post!.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // User info section
                            if (_postOwner != null) ...[
                              const Text(
                                'Usuario',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgTertiary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _postOwner!.getInitials(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // User details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _postOwner!.displayName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_postOwner!.postsCount} publicaciones',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Contact button (if not owner)
                            if (_post!.userId != _authService.currentUser?.uid)
                              Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _startChat,
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Enviar mensaje',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
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
                ),
    );
  }
}

