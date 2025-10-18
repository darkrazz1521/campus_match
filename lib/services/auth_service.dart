import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService.instance;

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

      User? user = userCredential.user;

      // Update display name
      await user?.updateDisplayName(fullName);

      if (user != null) {
        // 1️⃣ Initialize comprehensive Firestore profile
        await _userService.saveProfileData(
          uid: user.uid,
          name: fullName,
          gender: '',
          collegeYear: '',
          dob: '',
          bio: 'Hi there! Complete your profile to start matching.',
          photos: [],
          interests: [],
          branch: '',
        );

        // 2️⃣ Merge authentication-specific fields
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        }, SetOptions(merge: true));
      }

      // Send verification email
      await user?.sendEmailVerification();

      // Sign out user until verified
      await _auth.signOut();

      return null; // success
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

  /// 🧭 Check if user email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  /// 🔄 Resend verification email (even after logout)
  Future<String?> resendVerificationEmail({String? email, String? password}) async {
    try {
      User? user = _auth.currentUser;

      // Temporarily login if not already
      if (user == null && email != null && password != null) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
      }

      if (user == null) return "Unable to find user.";

      await user.reload();

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        return null; // Success
      } else {
        await _auth.signOut();
        return "Email already verified.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return "You've requested too many emails. Please wait a few minutes.";
      } else if (e.code == 'network-request-failed') {
        return "Network error. Please check your connection.";
      } else {
        return e.message ?? "Failed to resend verification email. Please try again.";
      }
    } catch (e) {
      return "Something went wrong while resending the email.";
    }
  }

  /// ✅ Update Firestore after email verification
  Future<void> updateEmailVerifiedStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });
      }
    }
  }

  /// 🔐 Login user and verify email status
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        await user.reload(); // refresh emailVerified

        if (user.emailVerified) {
          // Update Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
          return null; // login success
        } else {
          await _auth.signOut();
          return 'Please verify your email before logging in.';
        }
      }

      return 'Login failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email format.';
        default:
          return 'Login failed. Please try again.';
      }
    }
  }

  /// 🚪 Logout
  Future<void> logout() async => await _auth.signOut();
}
