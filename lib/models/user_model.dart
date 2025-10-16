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

  final bool isPremium;
  final int dailySwipeCount; 
  final DateTime? lastSwipeDate;

  // 🔹 New optional fields for computed data
  final double matchScore; // calculated in matchmaking
  final String distance;   // formatted like "3 km away"

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
    this.matchScore = 0.0,       // default when not provided
    this.distance = 'Unknown',   // default when not provided
    this.isPremium = false, // Default to free
    this.dailySwipeCount = 0,
    this.lastSwipeDate,
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
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      distance: json['distance'] ?? 'Unknown',
      isPremium: json['isPremium'] ?? false,
      dailySwipeCount: json['dailySwipeCount'] ?? 0,
      lastSwipeDate: (json['lastSwipeDate'] as Timestamp?)?.toDate(),
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
      'matchScore': matchScore,
      'distance': distance,
      'isPremium': isPremium,
      'dailySwipeCount': dailySwipeCount,
      'lastSwipeDate': lastSwipeDate,
    };
  }

  // Optional: convenience copyWith() method (useful later for updating matchScore/distance)
  UserModel copyWith({
    double? matchScore,
    String? distance,
    bool? isPremium,
    int? dailySwipeCount,
    DateTime? lastSwipeDate,
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
      matchScore: matchScore ?? this.matchScore,
      distance: distance ?? this.distance,
      isPremium: isPremium ?? this.isPremium,
      dailySwipeCount: dailySwipeCount ?? this.dailySwipeCount,
      lastSwipeDate: lastSwipeDate ?? this.lastSwipeDate,
    );
  }
}
