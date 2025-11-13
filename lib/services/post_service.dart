import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'storage_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<String> createPost(PostModel post, File? imageFile) async {
    try {
      String? imageUrl;
      
      if (imageFile != null) {
        imageUrl = await _storageService.uploadPostImage(imageFile, post.userId);
      }
      
      final postWithImage = PostModel(
        id: post.id,
        userId: post.userId,
        userName: post.userName,
        type: post.type,
        title: post.title,
        description: post.description,
        location: post.location,
        imageUrl: imageUrl ?? post.imageUrl,
        status: post.status,
        viewCount: post.viewCount,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      );

      DocumentReference docRef =
          await _firestore.collection('posts').add(postWithImage.toJson());

      await _updateUserPostCount(post.userId, increment: true);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      throw 'Error al crear la publicación';
    }
  }

  Future<void> updatePost(String postId, PostModel post, File? newImageFile) async {
    try {
      String? imageUrl = post.imageUrl;
      
      if (newImageFile != null) {
        if (post.imageUrl != null) {
          await _storageService.deleteImage(post.imageUrl!);
        }
        imageUrl = await _storageService.uploadPostImage(newImageFile, post.userId);
      }
      
      final updatedPost = PostModel(
        id: post.id,
        userId: post.userId,
        userName: post.userName,
        type: post.type,
        title: post.title,
        description: post.description,
        location: post.location,
        imageUrl: imageUrl,
        status: post.status,
        viewCount: post.viewCount,
        createdAt: post.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(postId).update({
        ...updatedPost.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating post: $e');
      throw 'Error al actualizar la publicación';
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
      PostModel? post = await getPostById(postId);
      
      if (post?.imageUrl != null) {
        await _storageService.deleteImage(post!.imageUrl!);
      }

      await _firestore.collection('posts').doc(postId).delete();

      await _updateUserPostCount(userId, increment: false);
    } catch (e) {
      print('Error deleting post: $e');
      throw 'Error al eliminar la publicación';
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('posts').doc(postId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['id'] = postId;
        return PostModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  Future<List<PostModel>> getPostsPaginated({
    PostType? type,
    PostStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('posts');

      if (status != null) {
        query = query.where('status', isEqualTo: status == PostStatus.active ? 'active' : 'resolved');
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type == PostType.lost ? 'lost' : 'found');
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot snapshot = await query.get();
      List<PostModel> posts = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        posts.add(PostModel.fromJson(data));
      }

      return posts;
    } catch (e) {
      print('Error getting paginated posts: $e');
      return [];
    }
  }

  Stream<List<PostModel>> getAllPosts({
    PostType? type,
    PostStatus? status,
  }) {
    Query query = _firestore.collection('posts').orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      List<PostModel> posts = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        PostModel post = PostModel.fromJson(data);

        bool matchesType = type == null || post.type == type;
        bool matchesStatus = status == null || post.status == status;

        if (matchesType && matchesStatus) {
          posts.add(post);
        }
      }

      return posts;
    });
  }

  Stream<List<PostModel>> getUserPosts(String userId, {PostStatus? status}) {
    Query query = _firestore
        .collection('posts')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      List<PostModel> posts = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        PostModel post = PostModel.fromJson(data);

        if (status == null || post.status == status) {
          posts.add(post);
        }
      }

      return posts;
    });
  }

  Future<List<PostModel>> searchPostsPaginated(String searchTerm, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      if (searchTerm.isEmpty) {
        return await getPostsPaginated(
          status: PostStatus.active,
          limit: limit,
          startAfter: startAfter,
        );
      }

      Query query = _firestore
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot snapshot = await query.get();
      List<PostModel> posts = [];
      String searchLower = searchTerm.toLowerCase();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        PostModel post = PostModel.fromJson(data);

        if (post.title.toLowerCase().contains(searchLower) ||
            post.description.toLowerCase().contains(searchLower) ||
            post.location.toLowerCase().contains(searchLower)) {
          posts.add(post);
        }
      }

      return posts;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  Stream<List<PostModel>> searchPosts(String searchTerm) {
    return getAllPosts().map((posts) {
      if (searchTerm.isEmpty) return posts;

      return posts
          .where((post) =>
              post.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
              post.description
                  .toLowerCase()
                  .contains(searchTerm.toLowerCase()) ||
              post.location.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  Future<void> updatePostStatus(
      String postId, PostStatus status, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': status == PostStatus.active ? 'active' : 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == PostStatus.resolved) {
        await _firestore.collection('users').doc(userId).update({
          'activePostsCount': FieldValue.increment(-1),
          'resolvedPostsCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error updating post status: $e');
      throw 'Error al actualizar el estado de la publicación';
    }
  }

  Future<void> _updateUserPostCount(String userId,
      {required bool increment}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(increment ? 1 : -1),
        'activePostsCount': FieldValue.increment(increment ? 1 : -1),
      });
    } catch (e) {
      print('Error updating user post count: $e');
    }
  }
}
