import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/app_theme.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'my_posts_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postService = PostService();
  final _searchController = TextEditingController();
  
  int _selectedIndex = 0;
  String _selectedFilter = 'Todos';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<PostModel>> _getPostsStream() {
    if (_searchQuery.isNotEmpty) {
      return _postService.searchPosts(_searchQuery);
    }

    switch (_selectedFilter) {
      case 'Perdidos':
        return _postService.getAllPosts(type: PostType.lost, status: PostStatus.active);
      case 'Encontrados':
        return _postService.getAllPosts(type: PostType.found, status: PostStatus.active);
      case 'Mis posts':
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? userId = authProvider.firebaseUser?.uid;
        if (userId != null) {
          return _postService.getUserPosts(userId, status: PostStatus.active);
        }
        return Stream.value([]);
      default:
        return _postService.getAllPosts(status: PostStatus.active);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex && index == 0) return;
    
    setState(() {
      _selectedIndex = index;
    });

    if (index != 0) {
      Widget screen;
      switch (index) {
        case 1:
          screen = const MyPostsScreen();
          break;
        case 2:
          screen = const ChatListScreen();
          break;
        case 3:
          screen = const ProfileScreen();
          break;
        default:
          return;
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar por título...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'Perdidos', 'Encontrados', 'Mis posts']
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: _selectedFilter == filter,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                selectedColor: AppTheme.primaryColor,
                                backgroundColor: AppTheme.bgTertiary,
                                labelStyle: TextStyle(
                                  color: _selectedFilter == filter
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: _selectedFilter == filter
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay publicaciones',
                          style: TextStyle(
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
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    PostModel post = posts[index];
                    bool isMyPost = post.userId == authProvider.firebaseUser?.uid;

                    return PostCard(
                      post: post,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(postId: post.id!),
                          ),
                        );
                      },
                      onChat: isMyPost ? null : () {
                        // Navigate to chat
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abriendo chat...')),
                        );
                      },
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Mis Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

