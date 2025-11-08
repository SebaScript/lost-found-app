import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';

class PostService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create a new post
  Future<String> createPost(PostModel post) async {
    try {
      DatabaseReference newPostRef = _database.child('posts').push();
      String postId = newPostRef.key!;
      
      await newPostRef.set(post.toJson());

      // Update user's post count
      await _updateUserPostCount(post.userId, increment: true);

      return postId;
    } catch (e) {
      print('Error creating post: $e');
      throw 'Error al crear la publicación';
    }
  }

  // Update post
  Future<void> updatePost(String postId, PostModel post) async {
    try {
      await _database.child('posts/$postId').update({
        ...post.toJson(),
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating post: $e');
      throw 'Error al actualizar la publicación';
    }
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _database.child('posts/$postId').remove();

      // Update user's post count
      await _updateUserPostCount(userId, increment: false);
    } catch (e) {
      print('Error deleting post: $e');
      throw 'Error al eliminar la publicación';
    }
  }

  // Get post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      DataSnapshot snapshot = await _database.child('posts/$postId').get();
      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = postId;
        return PostModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Get all posts (with optional filter)
  Stream<List<PostModel>> getAllPosts({
    PostType? type,
    PostStatus? status,
  }) {
    Query query = _database.child('posts').orderByChild('createdAt');

    return query.onValue.map((event) {
      List<PostModel> posts = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> postsMap = event.snapshot.value as Map;
        postsMap.forEach((key, value) {
          Map<String, dynamic> postData = Map<String, dynamic>.from(value as Map);
          postData['id'] = key;
          PostModel post = PostModel.fromJson(postData);
          
          // Apply filters
          bool matchesType = type == null || post.type == type;
          bool matchesStatus = status == null || post.status == status;
          
          if (matchesType && matchesStatus) {
            posts.add(post);
          }
        });
      }
      
      // Sort by createdAt descending
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // Get user's posts
  Stream<List<PostModel>> getUserPosts(String userId, {PostStatus? status}) {
    return _database.child('posts')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      List<PostModel> posts = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> postsMap = event.snapshot.value as Map;
        postsMap.forEach((key, value) {
          Map<String, dynamic> postData = Map<String, dynamic>.from(value as Map);
          postData['id'] = key;
          PostModel post = PostModel.fromJson(postData);
          
          // Apply status filter
          if (status == null || post.status == status) {
            posts.add(post);
          }
        });
      }
      
      // Sort by createdAt descending
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // Search posts
  Stream<List<PostModel>> searchPosts(String searchTerm) {
    return getAllPosts().map((posts) {
      if (searchTerm.isEmpty) return posts;
      
      return posts.where((post) =>
          post.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          post.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
          post.location.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();
    });
  }

  // Increment view count
  Future<void> incrementViewCount(String postId) async {
    try {
      DatabaseReference viewCountRef = _database.child('posts/$postId/viewCount');
      await viewCountRef.set(ServerValue.increment(1));
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Update post status
  Future<void> updatePostStatus(String postId, PostStatus status, String userId) async {
    try {
      await _database.child('posts/$postId').update({
        'status': status == PostStatus.active ? 'active' : 'resolved',
        'updatedAt': ServerValue.timestamp,
      });

      // Update user's active/resolved post counts
      if (status == PostStatus.resolved) {
        DatabaseReference userRef = _database.child('users/$userId');
        await userRef.update({
          'activePostsCount': ServerValue.increment(-1),
          'resolvedPostsCount': ServerValue.increment(1),
        });
      }
    } catch (e) {
      print('Error updating post status: $e');
      throw 'Error al actualizar el estado de la publicación';
    }
  }

  // Update user post count
  Future<void> _updateUserPostCount(String userId, {required bool increment}) async {
    try {
      DatabaseReference userRef = _database.child('users/$userId');
      await userRef.update({
        'postsCount': ServerValue.increment(increment ? 1 : -1),
        'activePostsCount': ServerValue.increment(increment ? 1 : -1),
      });
    } catch (e) {
      print('Error updating user post count: $e');
    }
  }
}
