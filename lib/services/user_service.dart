import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  static UserService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Get current logged-in UID
  Future<String> getCurrentUid() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  /// 🔹 Save or initialize user profile data
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
    bool isPremium = false,
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
      isPremium: isPremium,
    );

    await _firestore.collection('users').doc(uid).set(user.toJson(), SetOptions(merge: true));
  }

  /// 🔹 Fetch a single user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromJson(doc.data()!);
    return null;
  }

  /// 🔹 Fetch all users except current
  Future<List<UserModel>> getAllUsers(String currentUid) async {
    final query = await _firestore.collection('users').get();
    return query.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  /// 🔹 Fetch all users (raw)
  Future<List<UserModel>> fetchUsers() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  /// 🔹 Save premium filter preferences
  Future<void> saveFilterPreferences({
    required String uid,
    String? branch,
    String? collegeYear,
    List<String>? interests,
    double? maxDistanceKm,
  }) async {
    final data = {
      'filterPreferences': {
        if (branch != null) 'branch': branch,
        if (collegeYear != null) 'collegeYear': collegeYear,
        if (interests != null) 'interests': interests,
        if (maxDistanceKm != null) 'maxDistanceKm': maxDistanceKm,
      },
    };

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// 🔹 Get premium filter preferences
  Future<Map<String, dynamic>?> getFilterPreferences(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['filterPreferences'] != null
        ? Map<String, dynamic>.from(data!['filterPreferences'])
        : null;
  }

  /// 🔹 Reset daily counters if a new day
  void _maybeResetDailyCounters(UserModel user, DocumentReference userRef) {
    final now = DateTime.now();
    if (user.lastSwipeDate == null || !isSameDay(now, user.lastSwipeDate!)) {
      userRef.update({
        'dailySwipeCount': 0,
        'lastSwipeDate': now,
      });
    }
    if (user.lastUndoDate == null || !isSameDay(now, user.lastUndoDate!)) {
      userRef.update({
        'undosUsedToday': 0,
        'lastUndoDate': now,
      });
    }
    if (user.lastSuperLikeDate == null || !isSameDay(now, user.lastSuperLikeDate!)) {
      userRef.update({
        'superLikesUsedToday': 0,
        'lastSuperLikeDate': now,
      });
    }
  }

  /// 🔹 Handle swipes (like/pass/super-like)
  Future<Map<String, dynamic>> updateSwipe({
    required String currentUid,
    required String targetUid,
    required bool liked,
    bool superLike = false,
  }) async {
    final userRef = _firestore.collection('users').doc(currentUid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return {'success': false, 'isMatch': false};

    final currentUser = UserModel.fromJson(userDoc.data()!);

    _maybeResetDailyCounters(currentUser, userRef);

    // 🔸 Handle swipe limit for free users
    if (!currentUser.isPremium) {
      final now = DateTime.now();
      final lastSwipe = currentUser.lastSwipeDate;
      int currentCount = (lastSwipe == null || !isSameDay(now, lastSwipe))
          ? 0
          : currentUser.dailySwipeCount;
      const int swipeLimit = 50;

      if (currentCount >= swipeLimit) {
        return {'success': false, 'isMatch': false, 'message': 'Daily swipe limit reached.'};
      }

      await userRef.update({
        'dailySwipeCount': currentCount + 1,
        'lastSwipeDate': now,
      });
    }

    // 🔸 Handle super-like limit
    if (superLike && !currentUser.isPremium) {
      return {'success': false, 'isMatch': false, 'message': 'Super Like is a premium feature.'};
    }

    // 🔸 Update Firestore
    if (superLike) {
      final now = DateTime.now();
      int currentSuperCount = (currentUser.lastSuperLikeDate == null ||
              !isSameDay(now, currentUser.lastSuperLikeDate!))
          ? 0
          : currentUser.superLikesUsedToday;

      await userRef.update({
        'superLikesUsedToday': currentSuperCount + 1,
        'lastSuperLikeDate': now,
        'superLikedUsers': FieldValue.arrayUnion([targetUid]),
      });
    } else {
      await userRef.update({
        liked ? 'likedUsers' : 'passedUsers': FieldValue.arrayUnion([targetUid]),
      });
    }

    // 🔸 Check for match
    final targetRef = _firestore.collection('users').doc(targetUid);
    final targetDoc = await targetRef.get();
    bool isMatch = false;
    if (targetDoc.exists) {
      final targetUser = UserModel.fromJson(targetDoc.data()!);
      final targetLikedCurrent =
          targetUser.likedUsers.contains(currentUid) || targetUser.superLikedUsers.contains(currentUid);

      if ((liked && targetLikedCurrent) || (superLike && targetUser.likedUsers.contains(currentUid))) {
        await addMatch(currentUid, targetUid);
        isMatch = true;
      }
    }

    return {'success': true, 'isMatch': isMatch};
  }

  /// 🔹 Consume undo (free users limited)
  Future<bool> consumeUndo(String uid, {int maxFreeUndos = 1}) async {
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return false;

    final user = UserModel.fromJson(doc.data()!);
    final now = DateTime.now();
    int used = (user.lastUndoDate == null || !isSameDay(now, user.lastUndoDate!))
        ? 0
        : user.undosUsedToday;

    if (!user.isPremium && used >= maxFreeUndos) return false;

    await ref.update({
      'undosUsedToday': used + 1,
      'lastUndoDate': now,
    });
    return true;
  }

  /// 🔹 Add mutual match between two users
  Future<void> addMatch(String userA, String userB) async {
    final batch = _firestore.batch();
    final userARef = _firestore.collection('users').doc(userA);
    final userBRef = _firestore.collection('users').doc(userB);

    batch.update(userARef, {'matches': FieldValue.arrayUnion([userB])});
    batch.update(userBRef, {'matches': FieldValue.arrayUnion([userA])});
    await batch.commit();
  }

  /// 🔹 Helper: Check if two DateTimes are same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
