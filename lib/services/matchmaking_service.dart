import '../models/user_model.dart';
import 'user_service.dart';
import 'dart:math';

class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();
  static MatchmakingService get instance => _instance;

  final UserService _userService = UserService.instance;

  /// Fetch users that are not already swiped or matched
  

  /// Calculate compatibility match score
  /// Calculate compatibility match score
  double calculateMatchScore(UserModel userA, UserModel userB, {bool isSuperLikedByB = false}) {
    double score = 0;

    // Interests similarity
    final commonInterests =
        userA.interests.where((i) => userB.interests.contains(i)).length;
    score += commonInterests * 10;

    // Academic and personal compatibility
    if (userA.branch == userB.branch) score += 15;
    if (userA.collegeYear == userB.collegeYear) score += 10;
    if (userA.gender != userB.gender) score += 5;

    // Similar words in bio (soft text matching)
if (userA.bio.split(' ').any((word) => word.length > 2 && userB.bio.contains(word))) {
score += 5;
}

// Boost for super-like (Rule 1: +0.2 to final score)
// This now means userB (the profile being shown) super-liked userA (the current user)
if (isSuperLikedByB) score += 20; 

return (score / 100).clamp(0.0, 1.0);
}

  /// Core matching logic — now includes premium filters
  /// Core matching logic — now includes premium filters
  /// Core matching logic — now includes premium filters
  Future<List<UserModel>> processMatches({
    required List<UserModel> users,
    required UserModel currentUser, // Make sure this parameter is here
    Map<String, dynamic>? filters,
  }) async {
    // We no longer need to fetch currentUser, it's passed in.

    // Fetch all UIDs that have super-liked the current user
    // The crash is happening in this query.
    final superLikersQuery = await _userService.likesCollection
        .where('targetUid', isEqualTo: currentUser.uid)
        .where('superLike', isEqualTo: true)
        .where('liked', isEqualTo: true) // Ensure it's an active 'like'
        .get();

    final Set<String> superLikerUids = superLikersQuery.docs
        .map((doc) => doc['sourceUid'] as String)
        .toSet();

    List<UserModel> filteredUsers = users;

    // 🧩 1. Basic cleanup — remove incomplete profiles for premium users
    if (currentUser.isPremium) {
      filteredUsers = filteredUsers.where((u) {
        return u.photos.isNotEmpty && u.bio.isNotEmpty;
      }).toList();
    }

    // 🧠 2. Apply advanced filters — only for premium users
    if (currentUser.isPremium && filters != null) {
      // --- REMOVED ---
      // 'branch' filter is now done in the Firestore query (in UserService.getAllUsers)
      // 'collegeYear' filter is now done in the Firestore query
      // --- END REMOVED ---

      // --- KEPT ---
      // 'interests' and 'distance' are complex filters, so we
      // still apply them in-memory after the initial fetch.

      // Interests Filter
      if (filters['interests'] != null && filters['interests'] is List) {
        final selectedInterests = List<String>.from(filters['interests']);
        if (selectedInterests.isNotEmpty) {
          // Only filter if interests are selected
          filteredUsers = filteredUsers.where((u) {
            return u.interests.any((i) => selectedInterests.contains(i));
          }).toList();
        }
      }

      // Distance Filter (optional — assuming u.distance is a string like “12 km”)
      if (filters['maxDistanceKm'] != null) {
        final maxD = filters['maxDistanceKm'] as int;
        filteredUsers = filteredUsers.where((u) {
          try {
            final parts = u.distance.split(' ');
            final numKm = int.parse(parts.first);
            return numKm <= maxD;
          } catch (_) {
            return true;
          }
        }).toList();
      }
      // --- END KEPT ---
    }

    // 🎯 3. Compute match score + simulate distance
    final processed = filteredUsers.map((u) {
      // Check if this user 'u' is in the set of people who super-liked us
      final bool isSuperLikedByThisUser = superLikerUids.contains(u.uid);

      final matchScore = calculateMatchScore(currentUser, u,
          isSuperLikedByB: isSuperLikedByThisUser);

      // simulate random-ish distance for now (later use actual lat/lng)
      final distance = "${(10 + (u.name.hashCode % 90)).toString()} km";

      return u.copyWith(matchScore: matchScore, distance: distance);
    }).toList();

    // 🔝 4. Sort for premium users by match score (with weighted randomness)
final random = Random(); // Initialize random number generator

if (currentUser.isPremium) {
  print("   Applying premium weighted-random sort...");
  processed.sort((a, b) {
    // Apply a random "jitter" to each score, centered around 1.0
    // This creates a "weighted shuffle"
    // We use (0.8 + 0.4) to get a random multiplier between 0.8 and 1.2
    final double boostA = 0.8 + (random.nextDouble() * 0.4);
    final double boostB = 0.8 + (random.nextDouble() * 0.4);

    // Compare the "boosted" scores
    // Note: The super-like boost is already baked into the 'matchScore'
    return (b.matchScore * boostB).compareTo(a.matchScore * boostA);
  });
} else {
  // Optional: Even free users can get a basic shuffle
  // so they don't see the exact same order every time.
  processed.shuffle(random);
}

return processed;
  }

  /// Handle swipe action (like, nope, superlike)
  Future<void> handleSwipe({
    required UserModel currentUser,
    required UserModel targetUser,
    required bool liked,
    bool superLike = false,
  }) async {
    await _userService.updateSwipe(
      currentUid: currentUser.uid,
      targetUid: targetUser.uid,
      liked: liked,
      superLike: superLike,
    );
  }
}
