import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📝 Register user with Firebase Authentication
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Create user with email & password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Update display name in Firebase
      await userCredential.user?.updateDisplayName(fullName);

      // Send email verification (optional)
      await userCredential.user?.sendEmailVerification();

      // Save additional user data in Firestore (optional)
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      return null; // success (no error message)
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign-up is disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'An unknown error occurred. Please try again.';
      }
    } catch (e) {
      return 'Something went wrong. Please try again later.';
    }
  }
}
