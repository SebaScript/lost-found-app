import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createPost({
    required String userId,
    required String userName,
    required PostType type,
    required String title,
    required String description,
    required String location,
    File? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      PostModel newPost = PostModel(
        userId: userId,
        userName: userName,
        type: type,
        title: title,
        description: description,
        location: location,
        createdAt: DateTime.now(),
      );

      await _postService.createPost(newPost, imageFile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String userId,
    required String userName,
    required PostType type,
    required String title,
    required String description,
    required String location,
    String? existingImageUrl,
    File? newImageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      PostModel updatedPost = PostModel(
        id: postId,
        userId: userId,
        userName: userName,
        type: type,
        title: title,
        description: description,
        location: location,
        imageUrl: existingImageUrl,
        createdAt: DateTime.now(),
      );

      await _postService.updatePost(postId, updatedPost, newImageFile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postService.deletePost(postId, userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePostStatus(
      String postId, PostStatus status, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postService.updatePostStatus(postId, status, userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
