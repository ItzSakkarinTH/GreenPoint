class Quest {
  final String id;
  final String title;
  final String description;
  final String questType;
  final String recurrence;
  final int targetValue;
  final int currentValue;
  final int rewardPassXp;
  final int rewardPoints;
  final bool isCompleted;
  final bool isClaimed;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.questType,
    required this.recurrence,
    required this.targetValue,
    required this.currentValue,
    required this.rewardPassXp,
    required this.rewardPoints,
    required this.isCompleted,
    required this.isClaimed,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questType: json['questType'] ?? '',
      recurrence: json['recurrence'] ?? 'daily',
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      rewardPassXp: (json['rewardPassXp'] as num?)?.toInt() ?? 0,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
    );
  }
}
