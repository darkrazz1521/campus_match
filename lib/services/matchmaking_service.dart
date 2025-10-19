import '../models/user_model.dart';
import 'user_service.dart';

class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();
  static MatchmakingService get instance => _instance;

  final UserService _userService = UserService.instance;

  /// Fetch users that are not already swiped or matched
  Future<List<UserModel>> fetchPotentialMatches(UserModel currentUser) async {
    final allUsers = await _userService.getAllUsers(currentUser.uid);

    return allUsers.where((user) {
      final alreadySwiped = currentUser.likedUsers.contains(user.uid) ||
          currentUser.passedUsers.contains(user.uid) ||
          currentUser.matches.contains(user.uid);
      return !alreadySwiped;
    }).toList();
  }

  /// Calculate compatibility match score
  double calculateMatchScore(UserModel userA, UserModel userB, {bool isSuperLikedByA = false}) {
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
    // Similar words in bio (soft text matching)
if (userA.bio.split(' ').any((word) => word.length > 2 && userB.bio.contains(word))) {
score += 5;
}

// Boost for super-like (Rule 1: +0.2 to final score)
if (isSuperLikedByA) score += 20; 

return (score / 100).clamp(0.0, 1.0);
}

  /// Core matching logic — now includes premium filters
  Future<List<UserModel>> processMatches({
    required List<UserModel> users,
    Map<String, dynamic>? filters,
  }) async {
    final currentUid = await _userService.getCurrentUid();
    final currentUser = await _userService.getUserById(currentUid);
    if (currentUser == null) return users;

    List<UserModel> filteredUsers = users;

    // 🧩 1. Basic cleanup — remove incomplete profiles for premium users
    if (currentUser.isPremium) {
      filteredUsers = filteredUsers.where((u) {
        return u.photos.isNotEmpty && u.bio.isNotEmpty;
      }).toList();
    }

    // 🧠 2. Apply advanced filters — only for premium users
    if (currentUser.isPremium && filters != null) {
      // Branch Filter
      if (filters['branch'] != null && filters['branch'].toString().isNotEmpty) {
        filteredUsers = filteredUsers
            .where((u) => u.branch == filters['branch'])
            .toList();
      }

      // Year Filter
      if (filters['collegeYear'] != null &&
          filters['collegeYear'].toString().isNotEmpty) {
        filteredUsers = filteredUsers
            .where((u) => u.collegeYear == filters['collegeYear'])
            .toList();
      }

      // Interests Filter
      if (filters['interests'] != null && filters['interests'] is List) {
        final selectedInterests = List<String>.from(filters['interests']);
        filteredUsers = filteredUsers.where((u) {
          return u.interests.any((i) => selectedInterests.contains(i));
        }).toList();
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
    }

    // 🎯 3. Compute match score + simulate distance
    final processed = filteredUsers.map((u) {
      final isSuperLikedByCurrent = u.superLikedUsers.contains(currentUid);
      final matchScore =
          calculateMatchScore(currentUser, u, isSuperLikedByA: isSuperLikedByCurrent);

      // simulate random-ish distance for now (later use actual lat/lng)
      final distance = "${(10 + (u.name.hashCode % 90)).toString()} km";

      return u.copyWith(matchScore: matchScore, distance: distance);
    }).toList();

    // 🔝 4. Sort for premium users by match score
    if (currentUser.isPremium) {
      processed.sort((a, b) => b.matchScore.compareTo(a.matchScore));
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
