import 'badge_model.dart';

class Transaction {
  final String id;
  final String title;
  final String date;
  final int points;
  final int xp;
  final bool isNegative;

  Transaction({
    required this.id,
    required this.title,
    required this.date,
    required this.points,
    this.xp = 0,
    this.isNegative = false,
  });
}

class UserProfile {
  final String id;
  final String username;
  final String name;
  final int level;
  final int currentXp;
  final int maxXp;
  final int totalPoints;
  final double plasticReduced;
  final List<Badge> badges; // เพิ่มตัวแปรเก็บลิสต์เหรียญสะสม
  
  // Custom properties for dashboard support
  final int streakCount;
  final int todaysPoints;
  final String profileImage;

  UserProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.totalPoints,
    required this.plasticReduced,
    required this.badges,
    this.streakCount = 0,
    this.todaysPoints = 0,
    this.profileImage = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var badgeList = json['badges'] as List? ?? [];
    List<Badge> parsedBadges = badgeList.map((b) => Badge.fromJson(b)).toList();
    
    return UserProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      maxXp: (json['maxXp'] as num?)?.toInt() ?? 100,
      totalPoints: ((json['totalPointsEarned'] ?? json['totalPoints'] ?? json['points']) as num?)?.toInt() ?? 0,
      plasticReduced: (json['plasticReduced'] as num?)?.toDouble() ?? 0.0,
      badges: parsedBadges,
      streakCount: ((json['streakCount'] ?? json['streak']) as num?)?.toInt() ?? 0,
      todaysPoints: (json['todaysPoints'] as num?)?.toInt() ?? 0,
      profileImage: json['profileImage']?.toString() ?? '',
    );
  }
}
