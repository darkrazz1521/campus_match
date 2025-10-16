import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProfileService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick image
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload Base64 image to Firestore (instead of Realtime DB)
  Future<String?> uploadImage(File imageFile, String userId) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    final fileId = const Uuid().v4();

    await _firestore.collection('users').doc(userId).update({
      'photos': FieldValue.arrayUnion([base64String])
    });

    return base64String;
  } catch (e) {
    print("❌ Upload error: $e");
    return null;
  }
}


  /// Get user ID
  String? getCurrentUserId() => _auth.currentUser?.uid;

  /// Get name from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
  final uid = getCurrentUserId();
  if (uid == null) return null;

  final doc = await _firestore.collection('users').doc(uid).get();
  return doc.data();
}


  /// Save profile data → Firestore only
  Future<void> saveProfileData({
  required String name,
  required String gender,
  required String collegeYear,
  required String dob,
  required String bio,
  required List<String> photos,
  required List<String> interests,
}) async {
  final uid = getCurrentUserId();
  if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
    'fullName': name,
    'gender': gender,
    'collegeYear': collegeYear,
    'dob': dob,
    'bio': bio,
    'photos': photos,
    'interests': interests,
    'profileCompleted': true,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  }
}
