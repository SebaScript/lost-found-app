import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email.trim(),
          displayName: displayName.trim(),
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toJson());
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['uid'] = uid;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['uid'] = uid;
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    File? photoFile,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (photoFile != null) {
        UserModel? currentUser = await getUserData(uid);
        if (currentUser?.photoUrl != null) {
          await _storageService.deleteImage(currentUser!.photoUrl!);
        }
        
        String? photoUrl = await _storageService.uploadProfileImage(photoFile, uid);
        if (photoUrl != null) {
          updates['photoUrl'] = photoUrl;
        }
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Error al actualizar perfil';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación';
    }
  }
}
