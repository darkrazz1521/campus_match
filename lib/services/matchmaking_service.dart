import '../models/user_model.dart';
import 'user_service.dart';

class MatchmakingService {
  // 🔸 1. --- Singleton Pattern ---
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();
  static MatchmakingService get instance => _instance;

  // 🔸 2. --- Use your UserService singleton ---
  final UserService _userService = UserService.instance;

  /// 🧲 Fetch potential matches (excluding already swiped or matched)
  Future<List<UserModel>> fetchPotentialMatches(UserModel currentUser) async {
    final allUsers = await _userService.getAllUsers(currentUser.uid);

    return allUsers.where((user) {
      final alreadySwiped = currentUser.likedUsers.contains(user.uid) ||
          currentUser.passedUsers.contains(user.uid) ||
          currentUser.matches.contains(user.uid);
      return !alreadySwiped;
    }).toList();
  }

  /// 🧠 Calculate compatibility score (0–1)
  double calculateMatchScore(UserModel userA, UserModel userB) {
    double score = 0;

    // Common interests weight
    final commonInterests =
        userA.interests.where((i) => userB.interests.contains(i)).length;
    score += commonInterests * 10;

    // Same branch or college year adds weight
    if (userA.branch == userB.branch) score += 15;
    if (userA.collegeYear == userB.collegeYear) score += 10;

    // Gender difference adds mild diversity boost
    if (userA.gender != userB.gender) score += 5;

    // Bio similarity (simple keyword overlap)
    if (userA.bio.split(' ').any((word) => userB.bio.contains(word))) score += 5;

    return (score / 100).clamp(0.0, 1.0);
  }

  /// 🧮 Assign scores + mock distance + premium sorting
  Future<List<UserModel>> processMatches(List<UserModel> users) async {
    final currentUid = await _userService.getCurrentUid();
    final currentUser = await _userService.getUserById(currentUid);

    if (currentUser == null) return users;

    // 1. 🛡️ Profile Completeness Filter (Premium Feature)
    List<UserModel> filteredUsers = users;
    if (currentUser.isPremium) {
      filteredUsers = users.where((u) {
        return u.photos.isNotEmpty && u.bio.isNotEmpty;
      }).toList();
    }

    // 2. 🎯 Interest Filter Logic (if premium user sets filters)
    /*
    if (currentUser.isPremium && userFilters.hasInterestFilter) {
      filteredUsers = filteredUsers.where((u) => 
        u.interests.contains(userFilters.interest)
      ).toList();
    }
    */

    // 3. 📊 Add score & distance
    final processed = filteredUsers.map((u) {
      final matchScore = calculateMatchScore(currentUser, u);
      final distance = "${(10 + (u.name.hashCode % 90)).toString()} km";
      return u.copyWith(matchScore: matchScore, distance: distance);
    }).toList();

    // 4. 🏆 Sort if premium
    if (currentUser.isPremium) {
      processed.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    }

    return processed;
  }

  /// 💘 Handle swipe actions & check for mutual match
  Future<void> handleSwipe({
    required UserModel currentUser,
    required UserModel targetUser,
    required bool liked,
  }) async {
    await _userService.updateSwipe(
      currentUid: currentUser.uid,
      targetUid: targetUser.uid,
      liked: liked,
    );

    if (liked) {
      final target = await _userService.getUserById(targetUser.uid);
      if (target != null && target.likedUsers.contains(currentUser.uid)) {
        // 🎉 It's a match!
        await _userService.addMatch(currentUser.uid, targetUser.uid);
      }
    }
  }
}
