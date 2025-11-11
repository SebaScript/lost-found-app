import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPost(PostModel post) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('posts').add(post.toJson());

      await _updateUserPostCount(post.userId, increment: true);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      throw 'Error al crear la publicación';
    }
  }

  Future<void> updatePost(String postId, PostModel post) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        ...post.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating post: $e');
      throw 'Error al actualizar la publicación';
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
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
