import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
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

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Realtime Database
      if (result.user != null) {
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email.trim(),
          name: name.trim(),
          createdAt: DateTime.now(),
        );

        await _database
            .child('users/${result.user!.uid}')
            .set(newUser.toJson());
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Realtime Database
  Future<UserModel?> getUserData(String uid) async {
    try {
      DataSnapshot snapshot = await _database.child('users/$uid').get();
      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        data['uid'] = uid;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _database.child('users/$uid').update({
        ...data,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating user data: $e');
      throw 'Error al actualizar datos del usuario';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  // Get error message in Spanish
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
