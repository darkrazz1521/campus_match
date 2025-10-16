import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  // 🔹 1. --- Singleton Instance ---
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // 📌 Optional helper to access instance like UserService.instance
  static UserService get instance => _instance;

  // 🔹 2. --- Firebase Instances ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔸 Get current logged-in user's UID
  Future<String> getCurrentUid() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  /// 🔸 Save or update profile data for a user
  Future<void> saveProfileData({
    required String uid,
    required String name,
    required String gender,
    required String collegeYear,
    required String dob,
    required String bio,
    required List<String> photos,
    required List<String> interests,
    required String branch,
  }) async {
    final user = UserModel(
      uid: uid,
      name: name,
      gender: gender,
      collegeYear: collegeYear,
      dob: dob,
      bio: bio,
      photos: photos,
      interests: interests,
      branch: branch,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  /// 🔸 Fetch user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromJson(doc.data()!);
    return null;
  }

  /// 🔸 Fetch all users (except current user)
  Future<List<UserModel>> getAllUsers(String currentUid) async {
    final query = await _firestore.collection('users').get();
    return query.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  /// 🔸 Fetch all users (without filtering)
  Future<List<UserModel>> fetchUsers() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  /// 🔸 Update swipe action (like or pass)
  Future<bool> updateSwipe({
    required String currentUid,
    required String targetUid,
    required bool liked,
  }) async {
    final userRef = _firestore.collection('users').doc(currentUid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return false;

    final currentUser = UserModel.fromJson(userDoc.data()!);

    // 🛑 Swipe Limit Logic for Free Users
    if (!currentUser.isPremium) {
      final now = DateTime.now();
      final lastSwipe = currentUser.lastSwipeDate;

      // Reset counter if new day
      final shouldResetCount = lastSwipe == null || !isSameDay(now, lastSwipe);
      int currentCount = shouldResetCount ? 0 : currentUser.dailySwipeCount;
      const int swipeLimit = 50;

      if (currentCount >= swipeLimit) {
        return false; // Reached limit
      }

      await userRef.update({
        'dailySwipeCount': currentCount + 1,
        'lastSwipeDate': now,
      });
    }

    // ✅ Swiping Logic
    await userRef.update({
      liked ? 'likedUsers' : 'passedUsers': FieldValue.arrayUnion([targetUid]),
    });

    return true;
  }

  /// 🔸 Helper to check if two DateTimes are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 🔸 Add mutual match between two users
  Future<void> addMatch(String userA, String userB) async {
    final batch = _firestore.batch();

    final userARef = _firestore.collection('users').doc(userA);
    final userBRef = _firestore.collection('users').doc(userB);

    batch.update(userARef, {'matches': FieldValue.arrayUnion([userB])});
    batch.update(userBRef, {'matches': FieldValue.arrayUnion([userA])});

    await batch.commit();
  }
}
