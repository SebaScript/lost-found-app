import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../utils/app_theme.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _postService = PostService();
  final _authService = AuthService();
  PostStatus _selectedStatus = PostStatus.active;

  Future<void> _deletePost(String postId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _postService.deletePost(postId, _authService.currentUser!.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación eliminada'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
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
  }

  @override
  Widget build(BuildContext context) {
    String? userId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Mis Publicaciones'),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Activos',
                    selected: _selectedStatus == PostStatus.active,
                    onTap: () => setState(() => _selectedStatus = PostStatus.active),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Resueltos',
                    selected: _selectedStatus == PostStatus.resolved,
                    onTap: () => setState(() => _selectedStatus = PostStatus.resolved),
                  ),
                ),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: userId == null
                ? const Center(child: Text('No has iniciado sesión'))
                : StreamBuilder<List<PostModel>>(
                    stream: _postService.getUserPosts(userId, status: _selectedStatus),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes publicaciones ${_selectedStatus == PostStatus.active ? "activas" : "resueltas"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      List<PostModel> posts = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          PostModel post = posts[index];
                          return PostCard(
                            post: post,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(postId: post.id!),
                                ),
                              );
                            },
                            onChat: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreatePostScreen(post: post),
                                ),
                              );
                            },
                            onDelete: () => _deletePost(post.id!),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

