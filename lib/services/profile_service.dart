// lib/services/profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ProfileService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick an image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload image to Firebase Storage and return download URL
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final fileId = const Uuid().v4();
      final ref = _storage.ref().child('user_photos/$userId/$fileId.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  /// Fetch current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Fetch current user name from Firestore
  Future<String?> getCurrentUserName() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?['fullName'] != null) {
      return doc.data()?['fullName'];
    }
    return null;
  }

  /// Save profile data to Firestore
  Future<void> saveProfileData({
    required String name,
    required String college,
    required String major,
    required String bio,
    required List<String> photos,
    required List<String> interests,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'fullName': name,
      'college': college,
      'major': major,
      'bio': bio,
      'photos': photos,
      'interests': interests,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
