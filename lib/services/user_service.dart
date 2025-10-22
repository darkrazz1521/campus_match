import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


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
  CollectionReference get likesCollection => _firestore.collection('likes');
  final String _serverUrl = "https://campus-function.onrender.com";

      Map<String, dynamic> _createSwipeData({
required String sourceUid,
required String targetUid,
required bool liked,
bool superLike = false,
}) {
return {
'sourceUid': sourceUid,
'targetUid': targetUid,
'liked': liked,
'superLike': superLike,
'timestamp': FieldValue.serverTimestamp(),
};
}

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
  // In /services/user_service.dart

  // [REPLACED] Now accepts currentUser and filters to build an efficient query
  Future<List<UserModel>> getAllUsers(
    UserModel currentUser,
    Map<String, dynamic>? filters,
  ) async {
    final String currentUid = currentUser.uid;
    if (currentUid.isEmpty) {
      print("❌ ERROR in getAllUsers: Received empty currentUid!");
      return [];
    }
    print("   getAllUsers: Filtering out UID: $currentUid");

    // Start with the base query
    Query query = _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUid);

    // 💡 Apply Premium Filters AT THE QUERY LEVEL
    if (currentUser.isPremium && filters != null) {
      print("   Applying premium filters to query...");
      if (filters['branch'] != null && filters['branch'].toString().isNotEmpty) {
        try {
          // Note: This query requires a composite index in Firestore.
          // If this fails, go to the Firebase console and create the index
          // it suggests in the error log.
          query = query.where('branch', isEqualTo: filters['branch']);
          print("   -> Added filter: branch == ${filters['branch']}");
        } catch (e) {
          print(
              "   ⚠️ WARNING: Could not apply 'branch' filter. Check composite indexes in Firestore. $e");
        }
      }
      if (filters['collegeYear'] != null &&
          filters['collegeYear'].toString().isNotEmpty) {
        try {
          // Note: This query also requires a composite index.
          query = query.where('collegeYear', isEqualTo: filters['collegeYear']);
          print("   -> Added filter: collegeYear == ${filters['collegeYear']}");
        } catch (e) {
          print(
              "   ⚠️ WARNING: Could not apply 'collegeYear' filter. Check composite indexes in Firestore. $e");
        }
      }
      // Note: 'interests' (array-contains-any) and 'distance' (geo-query)
      // are more complex. We will leave them for in-memory filtering for now.
    }

    // 💡 Apply Free/Premium Limit
    final int limit = currentUser.isPremium ? 100 : 30;
    query = query.limit(limit);
    print("   Applying limit: $limit");

    // Execute the query
    final querySnapshot = await query.get();
    final allDocs = querySnapshot.docs;
    print("   getAllUsers: Fetched ${allDocs.length} total user docs.");

    // Parse the results
    final resultList = allDocs
        .map((doc) {
          try {
            return UserModel.fromJson(doc.data() as Map<String, dynamic>);
          } catch (e) {
            print("❌ ERROR parsing user data for doc ID ${doc.id}: $e");
            return null;
          }
        })
        .whereType<UserModel>()
        .toList();

    if (resultList.any((user) => user.uid == currentUid)) {
      print(
          "‼️ CRITICAL ERROR in getAllUsers: Result list STILL contains current user!");
    }

    return resultList;
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

  // Function to call your Render server
Future<bool> _triggerMatchCheck(String sourceUid, String targetUid) async {
  print("Calling server to check match: $sourceUid -> $targetUid");
  try {
    final response = await http.post(
      Uri.parse("$_serverUrl/checkMatch"), // Endpoint name from Render server code
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sourceUid': sourceUid,
        'targetUid': targetUid,
      }),
    ).timeout(const Duration(seconds: 20)); // Add a timeout

    print("Server response status: ${response.statusCode}");
    print("Server response body: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      // Return the 'isMatch' value from the server
      return data['isMatch'] as bool? ?? false; // Safely handle potential null
    } else {
      // Server error or unexpected response
      print("Match check request failed with status: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Failed to trigger match check (network error or timeout): $e");
    return false;
  }
}

Future<Map<String, dynamic>> updateSwipe({
  required String currentUid,
  required String targetUid,
  required bool liked,
  bool superLike = false,
}) async {
  final userRef = _firestore.collection('users').doc(currentUid);
  DocumentSnapshot userDocSnapshot; // Declare here
  try {
     userDocSnapshot = await userRef.get(); // Assign here
     if (!userDocSnapshot.exists) {
       print("User document $currentUid not found.");
       return {'success': false, 'isMatch': false, 'message': 'User not found.'};
     }
  } catch (e) {
      print("Error fetching user document $currentUid: $e");
      return {'success': false, 'isMatch': false, 'message': 'Failed to fetch user data.'};
  }

  // Ensure data exists before creating UserModel
  final userData = userDocSnapshot.data() as Map<String, dynamic>?;
  if (userData == null) {
      print("User data for $currentUid is null.");
      return {'success': false, 'isMatch': false, 'message': 'User data corrupted.'};
  }
  final currentUser = UserModel.fromJson(userData);


  _maybeResetDailyCounters(currentUser, userRef);

  // 🔸 Handle swipe limit for free users
  if (!currentUser.isPremium) {
    final now = DateTime.now();
    // Fetch the latest count *after* potential reset
    final latestUserDoc = await userRef.get();
    final latestUserData = latestUserDoc.data() ?? {};
    final lastSwipe = (latestUserData['lastSwipeDate'] as Timestamp?)?.toDate();
    int currentCount = (lastSwipe == null || !isSameDay(now, lastSwipe))
        ? 0
        : (latestUserData['dailySwipeCount'] as int? ?? 0); // Safely get count

    const int swipeLimit = 50; // Set your swipe limit

    if (currentCount >= swipeLimit) {
      print("User $currentUid reached daily swipe limit.");
      return {
        'success': false, // Indicate failure to swipe
        'isMatch': false,
        'message': 'Daily swipe limit reached.',
      };
    }

    // Increment swipe count atomically
    try {
        await userRef.update({
            'dailySwipeCount': FieldValue.increment(1),
            'lastSwipeDate': FieldValue.serverTimestamp(), // Use server time
        });
    } catch (e) {
        print("Error updating swipe count for $currentUid: $e");
        // Decide if you want to proceed or return error
        return {'success': false, 'isMatch': false, 'message': 'Failed to update swipe count.'};
    }
  }

  // 🔸 Handle super-like validation and limit (Rule 2)
  if (superLike) {
    if (!currentUser.isPremium) {
       print("Attempted Super Like by non-premium user $currentUid.");
       return {
         'success': false,
         'isMatch': false,
         'message': 'Super Like is a premium feature.',
       };
    }

    final now = DateTime.now();
    // Fetch latest count
    final latestUserDoc = await userRef.get();
    final latestUserData = latestUserDoc.data() ?? {};
    final lastSuperLike = (latestUserData['lastSuperLikeDate'] as Timestamp?)?.toDate();
    int currentSuperCount = (lastSuperLike == null || !isSameDay(now, lastSuperLike))
        ? 0
        : (latestUserData['superLikesUsedToday'] as int? ?? 0);

    // Enforce Super Like limit
    if (currentSuperCount >= maxSuperLikes) {
       print("User $currentUid reached Super Like limit.");
       return {
         'success': false,
         'isMatch': false,
         'message': 'Daily Super Like limit reached (Max $maxSuperLikes).',
       };
    }
    try {
        await userRef.update({
            'superLikesUsedToday': FieldValue.increment(1),
            'lastSuperLikeDate': FieldValue.serverTimestamp(),
        });
    } catch (e) {
         print("Error updating super like count for $currentUid: $e");
         return {'success': false, 'isMatch': false, 'message': 'Failed to update super like count.'};
    }
  }

  // 🔸 WRITE SWIPE DATA TO 'LIKES' COLLECTION
  String? newSwipeDocId;
  try {
    final newSwipeRef = await likesCollection.add(
      _createSwipeData(
        sourceUid: currentUid,
        targetUid: targetUid,
        liked: liked,
        superLike: superLike,
      ),
    );
    newSwipeDocId = newSwipeRef.id; // Store the ID

    // Update lastSwipedUserId for undo functionality
    await userRef.update({
      'lastSwipedUserId': newSwipeDocId,
    });
     print("Swipe recorded successfully for $currentUid -> $targetUid (Doc ID: $newSwipeDocId)");
  } catch (e) {
    print("❌ FAILED TO RECORD SWIPE IN LIKES COLLECTION for $currentUid -> $targetUid: $e");
    // Attempt to roll back swipe count if needed (optional, complex)
    // if (!currentUser.isPremium) { ... decrement dailySwipeCount ... }
    // if (superLike) { ... decrement superLikesUsedToday ... }
    return {
      'success': false,
      'isMatch': false,
      'message': 'Failed to record swipe.',
    };
  }

  // 🔸 CHECK FOR MUTUAL MATCH (CALL RENDER SERVER)
  bool isMatch = false; // Default to no match
  if (liked) { // Only check for match if it was a 'like' or 'superLike'
    print("Swipe was a like/superlike, triggering match check...");
    // We now AWAIT the result from our Render server
    isMatch = await _triggerMatchCheck(currentUid, targetUid);
    print("Match check result for $currentUid -> $targetUid: isMatch = $isMatch");
  } else {
      print("Swipe was not a like, skipping match check.");
  }

  // Return success and the result from the server
  return {'success': true, 'isMatch': isMatch};
}

  /// 🔹 Revert the last recorded swipe action
/// 🔹 Revert the last recorded swipe action
Future<Map<String, dynamic>> revertLastSwipe(
String currentUid, {
int maxFreeUndos = 1,
}) async {
final ref = _firestore.collection('users').doc(currentUid);
final doc = await ref.get();
if (!doc.exists) return {'success': false, 'message': 'User not found'};

final currentUser = UserModel.fromJson(doc.data()!);
// The lastSwipedUserId now holds the document ID of the swipe in the 'likes' collection.
final swipeDocId = currentUser.lastSwipedUserId;

if (swipeDocId == null) {
return {'success': false, 'message': 'No recent swipe to undo.'};
}

// Fetch the swipe data to identify the target user and swipe type
final swipeDoc = await likesCollection.doc(swipeDocId).get();
if (!swipeDoc.exists) {
await ref.update({'lastSwipedUserId': FieldValue.delete()});
return {'success': false, 'message': 'Original swipe record not found.'};
}

// Explicitly cast data to access fields safely
final swipeData = swipeDoc.data() as Map<String, dynamic>?;
if (swipeData == null) {
 await ref.update({'lastSwipedUserId': FieldValue.delete()});
 return {'success': false, 'message': 'Original swipe data is empty.'};
}
final targetUid = swipeData['targetUid'] as String?;
final bool wasSuperLike = swipeData['superLike']?? false;
final bool wasLiked = swipeData['liked']?? false;

if (targetUid == null) {
return {'success': false, 'message': 'Swipe data corrupted (Target UID missing).'};
}

// 1. Consume undo count
final undoAllowed = await consumeUndo(
currentUid,
maxFreeUndos: maxFreeUndos,
);

if (!undoAllowed) {
return {'success': false, 'message': 'Daily undo limit reached.'};
}

final batch = _firestore.batch();
final targetRef = _firestore.collection('users').doc(targetUid);

// 2. DELETE THE SWIPE RECORD FROM THE LIKES COLLECTION
batch.delete(likesCollection.doc(swipeDocId));

// 3. Update Current User's profile
Map<String, dynamic> updateData = {
'lastSwipedUserId': FieldValue.delete(),
};

// Decrement daily swipe counter if it was a free user's standard swipe
if (!currentUser.isPremium &&!wasSuperLike && wasLiked) {
// FIX: Assign FieldValue.increment to the correct key in the map
updateData['dailySwipeCount'] = FieldValue.increment(-1);

}

batch.update(ref, updateData);

// 4. Check if the reversed swipe was a match, and remove the match entry
// NOTE: This check still relies on the match being recorded in the user document.
if (doc.data()?['matches']!= null && 
(doc.data()!['matches'] as List).contains(targetUid)) {
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

Future<bool> consumeUndo(String uid, {int maxFreeUndos = 1}) async {
final ref = _firestore.collection('users').doc(uid);
final doc = await ref.get();
if (!doc.exists) return false;

final user = UserModel.fromJson(doc.data()!);
final now = DateTime.now();
int used =
(user.lastUndoDate == null ||!isSameDay(now, user.lastUndoDate!))
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

static bool isSameDay(DateTime a, DateTime b) {
return a.year == b.year && a.month == b.month && a.day == b.day;
}

}
