import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String gender;
  final String collegeYear;
  final String dob;
  final String bio;
  final List<String> photos;
  final List<String> interests;
  final String branch;
  final List<String> likedUsers;
  final List<String> passedUsers;
  final List<String> matches;

  // NEW: super-liked tracking + undo counts and daily counters
  final List<String> superLikedUsers;

  final bool isPremium;
  final int dailySwipeCount;
  final DateTime? lastSwipeDate;

  // NEW: undo/super-like daily usage tracking
  final int undosUsedToday;
  final DateTime? lastUndoDate;
  final int superLikesUsedToday;
  final DateTime? lastSuperLikeDate;

  // NEW: computed fields used in UI
  final double matchScore;
  final String distance;
  final String? lastSwipedUserId;


  UserModel({
    required this.uid,
    required this.name,
    required this.gender,
    required this.collegeYear,
    required this.dob,
    required this.bio,
    required this.photos,
    required this.interests,
    required this.branch,
    this.likedUsers = const [],
    this.passedUsers = const [],
    this.matches = const [],
    this.superLikedUsers = const [],
    this.isPremium = false,
    this.lastSwipedUserId,
    this.dailySwipeCount = 0,
    this.lastSwipeDate,
    this.undosUsedToday = 0,
    this.lastUndoDate,
    this.superLikesUsedToday = 0,
    this.lastSuperLikeDate,
    this.matchScore = 0.0,
    this.distance = 'Unknown',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      collegeYear: json['collegeYear'] ?? '',
      dob: json['dob'] ?? '',
      bio: json['bio'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      branch: json['branch'] ?? '',
      likedUsers: List<String>.from(json['likedUsers'] ?? []),
      passedUsers: List<String>.from(json['passedUsers'] ?? []),
      matches: List<String>.from(json['matches'] ?? []),
      superLikedUsers: List<String>.from(json['superLikedUsers'] ?? []),
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      distance: json['distance'] ?? 'Unknown',
      isPremium: json['isPremium'] ?? false,
      dailySwipeCount: json['dailySwipeCount'] ?? 0,
      lastSwipeDate:
          (json['lastSwipeDate'] as Timestamp?)?.toDate() ??
          (json['lastSwipeDate'] is String
              ? DateTime.tryParse(json['lastSwipeDate'])
              : null),
      undosUsedToday: json['undosUsedToday'] ?? 0,
      lastUndoDate:
          (json['lastUndoDate'] as Timestamp?)?.toDate() ??
          (json['lastUndoDate'] is String
              ? DateTime.tryParse(json['lastUndoDate'])
              : null),
      superLikesUsedToday: json['superLikesUsedToday'] ?? 0,
    lastSuperLikeDate: (json['lastSuperLikeDate'] as Timestamp?)?.toDate() ??
        (json['lastSuperLikeDate'] is String
            ? DateTime.tryParse(json['lastSuperLikeDate'])
            : null),
      lastSwipedUserId: json['lastSwipedUserId'], // 🆕 Add this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'gender': gender,
      'collegeYear': collegeYear,
      'dob': dob,
      'bio': bio,
      'photos': photos,
      'interests': interests,
      'branch': branch,
      'likedUsers': likedUsers,
      'passedUsers': passedUsers,
      'matches': matches,
      'superLikedUsers': superLikedUsers,
      'matchScore': matchScore,
      'distance': distance,
      'isPremium': isPremium,
      'dailySwipeCount': dailySwipeCount,
      'lastSwipeDate': lastSwipeDate,
      'undosUsedToday': undosUsedToday,
      'lastUndoDate': lastUndoDate,
      'superLikesUsedToday': superLikesUsedToday,
      'lastSuperLikeDate': lastSuperLikeDate,
      'lastSwipedUserId': lastSwipedUserId,
    };
  }

  UserModel copyWith({
    double? matchScore,
    String? distance,
    bool? isPremium,
    int? dailySwipeCount,
    DateTime? lastSwipeDate,
    int? undosUsedToday,
    DateTime? lastUndoDate,
    int? superLikesUsedToday,
    DateTime? lastSuperLikeDate,
    String? lastSwipedUserId,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      gender: gender,
      collegeYear: collegeYear,
      dob: dob,
      bio: bio,
      photos: photos,
      interests: interests,
      branch: branch,
      likedUsers: likedUsers,
      passedUsers: passedUsers,
      matches: matches,
      superLikedUsers: superLikedUsers,
      matchScore: matchScore ?? this.matchScore,
      distance: distance ?? this.distance,
      isPremium: isPremium ?? this.isPremium,
      dailySwipeCount: dailySwipeCount ?? this.dailySwipeCount,
      lastSwipeDate: lastSwipeDate ?? this.lastSwipeDate,
      undosUsedToday: undosUsedToday ?? this.undosUsedToday,
      lastUndoDate: lastUndoDate ?? this.lastUndoDate,
      superLikesUsedToday: superLikesUsedToday ?? this.superLikesUsedToday,
      lastSuperLikeDate: lastSuperLikeDate ?? this.lastSuperLikeDate,
      lastSwipedUserId: lastSwipedUserId?? this.lastSwipedUserId,
    );
  }
}
