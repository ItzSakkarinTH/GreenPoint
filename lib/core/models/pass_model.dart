class PassTier {
  final String id;
  final int tier;
  final int requiredXp;
  final String rewardType;
  final String rewardValue;
  final String rewardTitle;
  final String rewardIcon;

  PassTier({
    required this.id,
    required this.tier,
    required this.requiredXp,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardTitle,
    required this.rewardIcon,
  });

  factory PassTier.fromJson(Map<String, dynamic> json) {
    return PassTier(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      requiredXp: (json['requiredXp'] as num?)?.toInt() ?? 0,
      rewardType: json['rewardType'] ?? '',
      rewardValue: json['rewardValue']?.toString() ?? '',
      rewardTitle: json['rewardTitle'] ?? '',
      rewardIcon: json['rewardIcon'] ?? '',
    );
  }
}

class UserPassProgress {
  final int passXp;
  final int currentTier;
  final List<int> claimedTiers;
  final List<PassTier> tiers;

  UserPassProgress({
    required this.passXp,
    required this.currentTier,
    required this.claimedTiers,
    required this.tiers,
  });

  factory UserPassProgress.fromJson(Map<String, dynamic> json) {
    var tierList = json['tiers'] as List? ?? [];
    List<PassTier> parsedTiers = tierList.map((t) => PassTier.fromJson(t)).toList();
    var claimedList = json['claimedTiers'] as List? ?? [];
    List<int> parsedClaimed = claimedList.map((c) => (c as num).toInt()).toList();

    return UserPassProgress(
      passXp: (json['passXp'] as num?)?.toInt() ?? 0,
      currentTier: (json['currentTier'] as num?)?.toInt() ?? 0,
      claimedTiers: parsedClaimed,
      tiers: parsedTiers,
    );
  }
}
