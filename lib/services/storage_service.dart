import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  Future<String?> uploadPostImage(File imageFile, String userId) async {
    try {
      String fileName =
          'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        Uint8List imageData = await _getImageBytes(imageFile.path);
        uploadTask = ref.putData(imageData);
      } else {
        uploadTask = ref.putFile(imageFile);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw 'Error al subir la imagen';
    }
  }

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      String fileName = 'profile/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        Uint8List imageData = await _getImageBytes(imageFile.path);
        uploadTask = ref.putData(imageData);
      } else {
        uploadTask = ref.putFile(imageFile);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw 'Error al subir la imagen de perfil';
    }
  }

  Future<Uint8List> _getImageBytes(String path) async {
    if (kIsWeb) {
      final XFile file = XFile(path);
      return await file.readAsBytes();
    } else {
      final File file = File(path);
      return await file.readAsBytes();
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
