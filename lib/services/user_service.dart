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
  final int maxSuperLikes = 10; // NEW: Premium Super Like limit (Rule 2)
  final int maxPremiumUndos =
      10; // NEW: Undo limit after super likes exhausted (Rule 3)

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

    await _firestore
        .collection('users')
        .doc(uid)
        .set(user.toJson(), SetOptions(merge: true));
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

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
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
      userRef.update({'dailySwipeCount': 0, 'lastSwipeDate': now});
    }
    if (user.lastUndoDate == null || !isSameDay(now, user.lastUndoDate!)) {
      userRef.update({'undosUsedToday': 0, 'lastUndoDate': now});
    }
    if (user.lastSuperLikeDate == null ||
        !isSameDay(now, user.lastSuperLikeDate!)) {
      userRef.update({'superLikesUsedToday': 0, 'lastSuperLikeDate': now});
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
        return {
          'success': false,
          'isMatch': false,
          'message': 'Daily swipe limit reached.',
        };
      }

      await userRef.update({
        'dailySwipeCount': currentCount + 1,
        'lastSwipeDate': now,
      });
    }

    // 🔸 Handle super-like limit
    if (superLike && !currentUser.isPremium) {
      return {
        'success': false,
        'isMatch': false,
        'message': 'Super Like is a premium feature.',
      };
    }

    // 🔸 Update Firestore
    // 🔸 Handle super-like validation and limit (Rule 2)
    if (superLike) {
      if (!currentUser.isPremium) {
        return {
          'success': false,
          'isMatch': false,
          'message': 'Super Like is a premium feature.',
        };
      }

      final now = DateTime.now();
      int currentSuperCount =
          (currentUser.lastSuperLikeDate == null ||
              !isSameDay(now, currentUser.lastSuperLikeDate!))
          ? 0
          : currentUser.superLikesUsedToday;

      // Enforce Super Like limit
      if (currentSuperCount >= maxSuperLikes) {
        return {
          'success': false,
          'isMatch': false,
          'message':
              'Daily Super Like limit reached (Max $maxSuperLikes). You can now use your free Undos.',
        };
      }

      await userRef.update({
        'superLikesUsedToday': currentSuperCount + 1,
        'lastSuperLikeDate': now,
        'superLikedUsers': FieldValue.arrayUnion([targetUid]),
        'lastSwipedUserId': targetUid, // 🆕 Track last swipe
      });
    } else {
      await userRef.update({
        liked ? 'likedUsers' : 'passedUsers': FieldValue.arrayUnion([
          targetUid,
        ]),
        'lastSwipedUserId': targetUid, // 🆕 Track last swipe
      });
    }

    // 🔸 Check for match
    final targetRef = _firestore.collection('users').doc(targetUid);
    final targetDoc = await targetRef.get();
    bool isMatch = false;
    if (targetDoc.exists) {
      final targetUser = UserModel.fromJson(targetDoc.data()!);
      final targetLikedCurrent =
          targetUser.likedUsers.contains(currentUid) ||
          targetUser.superLikedUsers.contains(currentUid);
          print('CURRENT UID: $currentUid');
print('TARGET UID: $targetUid');
print('TARGET liked list: ${targetUser.likedUsers}');
print('TARGET superliked list: ${targetUser.superLikedUsers}');
print('LIKED = $liked, SUPERLIKE = $superLike');


      if ((liked && targetLikedCurrent) ||
          (superLike && targetUser.likedUsers.contains(currentUid))) {
        // Match Found! Execute atomic match update (This replaces addMatch call)
        try {
          final matchBatch = _firestore.batch();

          // 1. Update Current User's matches
          matchBatch.update(userRef, {
            'matches': FieldValue.arrayUnion([targetUid]),
          });

          // 2. Update Target User's matches
          matchBatch.update(targetRef, {
            'matches': FieldValue.arrayUnion([currentUid]),
          });

          await matchBatch.commit();
          isMatch = true;
        } catch (e) {
          // Log the failure to debug why the match wasn't recorded
          print("MATCH CREATION FAILED: $e");
          isMatch = false;
        }
      }
    }

    return {'success': true, 'isMatch': isMatch};
  }

  /// 🔹 Revert the last recorded swipe action
  Future<Map<String, dynamic>> revertLastSwipe(
    String currentUid, {
    int maxFreeUndos = 1,
  }) async {
    final ref = _firestore.collection('users').doc(currentUid);
    final doc = await ref.get();
    if (!doc.exists) return {'success': false, 'message': 'User not found'};

    // We fetch the current user data to perform the rollback logic
    final currentUser = UserModel.fromJson(doc.data()!);
    final targetUid = currentUser.lastSwipedUserId;

    if (targetUid == null) {
      return {'success': false, 'message': 'No recent swipe to undo.'};
    }

    // 1. Consume undo count - utilizes the existing consumption logic
    // Note: For premium users, consumeUndo always returns true
    final undoAllowed = await consumeUndo(
      currentUid,
      maxFreeUndos: maxFreeUndos,
    );

    if (!undoAllowed) {
      return {'success': false, 'message': 'Daily undo limit reached.'};
    }

    // 2. Determine which list to revert the swipe from
    bool wasSuperLike = currentUser.superLikedUsers.contains(targetUid);
    bool wasLike = currentUser.likedUsers.contains(targetUid);
    bool wasPassed = currentUser.passedUsers.contains(targetUid);

    if (!wasSuperLike && !wasLike && !wasPassed) {
      await ref.update({'lastSwipedUserId': FieldValue.delete()});
      return {'success': true, 'message': 'Undo successful (no swipe needed).'};
    }
    final batch = _firestore.batch();
    final targetRef = _firestore.collection('users').doc(targetUid);

    // 3. Revert the swipe for the current user
    final String fieldToRemove = wasSuperLike
        ? 'superLikedUsers'
        : wasLike
        ? 'likedUsers'
        : 'passedUsers';

    Map<String, dynamic> updateData = {
      fieldToRemove: FieldValue.arrayRemove([targetUid]),
      // Clear the last swipe ID to prevent double undo
      'lastSwipedUserId': FieldValue.delete(),
    };

    // Decrement daily swipe counter if it was a free user's standard swipe
    if (!currentUser.isPremium && !wasSuperLike) {
      // FIX: Correctly assign FieldValue.increment to the map key 'dailySwipeCount'
      updateData['dailySwipeCount'] = FieldValue.increment(-1);
    }

    batch.update(ref, updateData);

    // 4. Check if the reversed swipe was a match, and remove the match entry
    if (currentUser.matches.contains(targetUid)) {
      // Remove match from both users
      batch.update(ref, {
        'matches': FieldValue.arrayRemove([targetUid]),
      });
      batch.update(targetRef, {
        'matches': FieldValue.arrayRemove([currentUid]),
      });
    }

    await batch.commit();
    return {'success': true, 'message': 'Swipe undone successfully.'};
  }

  /// 🔹 Consume undo (free users limited)
  Future<bool> consumeUndo(String uid, {int maxFreeUndos = 1}) async {
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return false;

    final user = UserModel.fromJson(doc.data()!);
    final now = DateTime.now();
    int used =
        (user.lastUndoDate == null || !isSameDay(now, user.lastUndoDate!))
        ? 0
        : user.undosUsedToday;

    // Determine max allowed undos based on the limit passed from UI (Rule 3)
    int maxAllowedUndos = maxFreeUndos;

    if (user.isPremium && maxFreeUndos > 1) {
      // If premium and the UI passed a higher limit (10), enforce that limit.
      maxAllowedUndos = maxPremiumUndos;
    }

    if (used >= maxAllowedUndos) return false;

    await ref.update({'undosUsedToday': used + 1, 'lastUndoDate': now});
    return true;
  }


  /// 🔹 Helper: Check if two DateTimes are same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
