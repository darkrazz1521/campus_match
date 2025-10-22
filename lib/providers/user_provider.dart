import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool get isPremium => _currentUser?.isPremium ?? false;

  // Constructor: Listen to auth changes
  UserProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // When auth state changes, fetch user data or clear it
  // In /providers/user_provider.dart

  Future<void> _onAuthStateChanged(User? user) async {
    print("UserProvider._onAuthStateChanged: User is ${user?.uid ?? 'null'}");
    if (user != null) {
      await fetchCurrentUser(user.uid); // Fetch data FIRST
      if (_currentUser != null) { // Check if fetch was successful
        _saveFcmToken(_currentUser!.uid);
        print("   User loaded: ${_currentUser!.uid}");
      } else {
         print("   Failed to fetch user data after auth change.");
         // Handle error case - maybe sign out user?
         // For now, setting loading to false and notifying is okay.
         _isLoading = false;
         notifyListeners();
      }
    } else {
      _currentUser = null;
      _isLoading = false; // Set loading false on logout
      notifyListeners(); // Notify UI about logout
      print("   User logged out.");
    }
  }

  Future<void> fetchCurrentUser(String uid) async {
    print("UserProvider.fetchCurrentUser: Fetching data for $uid...");
    _isLoading = true;
    notifyListeners(); // Notify UI that loading started

    _currentUser = await _userService.getUserById(uid); // Await the fetch

    _isLoading = false; // Set loading false AFTER fetch completes
    notifyListeners(); // Notify UI that loading finished (with or without user data)
    print("   Fetch complete. User data ${ _currentUser != null ? 'loaded' : 'NOT found'}.");
  }

  // This logic is moved from HomeScreen
  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM Token saved by Provider: $token');
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Call this after profile setup is saved
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await fetchCurrentUser(_currentUser!.uid);
    }
  }
}