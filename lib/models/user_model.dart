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
  final bool? isOnline;

  

  // Premium & limits
  final bool isPremium;
  final int dailySwipeCount;
  final DateTime? lastSwipeDate;

  // Undo & superlike usage tracking
  final int undosUsedToday;
  final DateTime? lastUndoDate;
  final int superLikesUsedToday;
  final DateTime? lastSuperLikeDate;

  // Computed/UI fields (not stored in Firestore always)
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
    this.isPremium = false,
    this.dailySwipeCount = 0,
    this.lastSwipeDate,
    this.undosUsedToday = 0,
    this.lastUndoDate,
    this.superLikesUsedToday = 0,
    this.lastSuperLikeDate,
    this.matchScore = 0.0,
    this.distance = 'Unknown',
    this.lastSwipedUserId,
    this.isOnline,
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
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      distance: json['distance'] ?? 'Unknown',
      isPremium: json['isPremium'] ?? false,
      dailySwipeCount: json['dailySwipeCount'] ?? 0,

      // Date parsing for Firestore Timestamp or String ISO date
      lastSwipeDate:
          (json['lastSwipeDate'] is Timestamp)
              ? (json['lastSwipeDate'] as Timestamp).toDate()
              : (json['lastSwipeDate'] is String
                  ? DateTime.tryParse(json['lastSwipeDate'])
                  : null),

      undosUsedToday: json['undosUsedToday'] ?? 0,
      lastUndoDate:
          (json['lastUndoDate'] is Timestamp)
              ? (json['lastUndoDate'] as Timestamp).toDate()
              : (json['lastUndoDate'] is String
                  ? DateTime.tryParse(json['lastUndoDate'])
                  : null),

      superLikesUsedToday: json['superLikesUsedToday'] ?? 0,
      lastSuperLikeDate:
          (json['lastSuperLikeDate'] is Timestamp)
              ? (json['lastSuperLikeDate'] as Timestamp).toDate()
              : (json['lastSuperLikeDate'] is String
                  ? DateTime.tryParse(json['lastSuperLikeDate'])
                  : null),

      lastSwipedUserId: json['lastSwipedUserId'],
      isOnline: json['isOnline'],
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
      'isOnline': isOnline,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? gender,
    String? collegeYear,
    String? dob,
    String? bio,
    List<String>? photos,
    List<String>? interests,
    String? branch,
    List<String>? likedUsers,
    List<String>? passedUsers,
    List<String>? matches,
    List<String>? superLikedUsers,
    bool? isPremium,
    int? dailySwipeCount,
    DateTime? lastSwipeDate,
    int? undosUsedToday,
    DateTime? lastUndoDate,
    int? superLikesUsedToday,
    DateTime? lastSuperLikeDate,
    double? matchScore,
    String? distance,
    String? lastSwipedUserId,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      collegeYear: collegeYear ?? this.collegeYear,
      dob: dob ?? this.dob,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      branch: branch ?? this.branch,
      isPremium: isPremium ?? this.isPremium,
      dailySwipeCount: dailySwipeCount ?? this.dailySwipeCount,
      lastSwipeDate: lastSwipeDate ?? this.lastSwipeDate,
      undosUsedToday: undosUsedToday ?? this.undosUsedToday,
      lastUndoDate: lastUndoDate ?? this.lastUndoDate,
      superLikesUsedToday: superLikesUsedToday ?? this.superLikesUsedToday,
      lastSuperLikeDate: lastSuperLikeDate ?? this.lastSuperLikeDate,
      matchScore: matchScore ?? this.matchScore,
      distance: distance ?? this.distance,
      lastSwipedUserId: lastSwipedUserId ?? this.lastSwipedUserId,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
