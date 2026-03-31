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
  final String name;
  final int level;
  final int currentXp;
  final int maxXp;
  final int plasticReduced;
  final int totalPoints;

  UserProfile({
    required this.name,
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.plasticReduced,
    this.totalPoints = 0,
  });
}
