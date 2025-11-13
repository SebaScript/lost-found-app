import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../utils/app_theme.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'my_posts_screen.dart';
import 'chat_list_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postService = PostService();
  final _authService = AuthService();
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  
  int _selectedIndex = 0;
  String _selectedFilter = 'Todos';
  String _searchQuery = '';
  
  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _posts = [];
      _lastDocument = null;
      _hasMore = true;
    });

    await _loadMorePosts();
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<PostModel> newPosts;
      
      if (_searchQuery.isNotEmpty) {
        newPosts = await _postService.searchPostsPaginated(
          _searchQuery,
          limit: 20,
          startAfter: _lastDocument,
        );
      } else if (_selectedFilter == 'Mis posts') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? userId = authProvider.firebaseUser?.uid;
        
        if (userId == null) {
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
          return;
        }
        
        QuerySnapshot snapshot = await _firestore
            .collection('posts')
            .where('ownerId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        
        newPosts = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return PostModel.fromJson(data);
        }).toList();
        
        if (newPosts.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
      } else {
        PostType? type;
        if (_selectedFilter == 'Perdidos') type = PostType.lost;
        if (_selectedFilter == 'Encontrados') type = PostType.found;
        
        newPosts = await _postService.getPostsPaginated(
          type: type,
          status: PostStatus.active,
          limit: 20,
          startAfter: _lastDocument,
        );
      }

      if (newPosts.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      if (_selectedFilter != 'Mis posts') {
        DocumentSnapshot? lastDoc = await _getLastDocument(newPosts.last);
        _lastDocument = lastDoc;
      }
      
      setState(() {
        _posts.addAll(newPosts);
        _isLoading = false;
        _hasMore = newPosts.length >= 20;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<DocumentSnapshot?> _getLastDocument(PostModel post) async {
    try {
      return await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .get();
    } catch (e) {
      print('Error getting last document: $e');
      return null;
    }
  }


  Future<void> _startChat(PostModel post) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo chat...')),
        );
      }

      // Get current user data
      UserModel? currentUser = await _authService.getUserData(
        _authService.currentUser!.uid,
      );

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener datos del usuario'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Get post owner data
      UserModel? postOwner = await _authService.getUserData(post.userId);

      if (postOwner == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener datos del propietario'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Create or get chat
      String chatId = await _chatService.createOrGetChat(
        postId: post.id!,
        postTitle: post.title,
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        receiverId: postOwner.uid,
        receiverName: postOwner.displayName,
      );

      // Navigate to chat screen
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
                      _loadPosts();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar por título, descripción o ubicación...',
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
                                  _loadPosts();
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
            child: _posts.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _posts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          PostModel post = _posts[index];
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          bool isMyPost = post.userId == authProvider.firebaseUser?.uid;

                          return PostCard(
                            post: post,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PostDetailScreen(postId: post.id!),
                                ),
                              );
                            },
                            onChat: isMyPost ? null : () => _startChat(post),
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

