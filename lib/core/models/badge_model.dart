class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String rarity; // common, rare, epic, legendary
  final String criteriaType; // plastic_reduced, total_points, level
  final int criteriaValue;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.rarity,
    required this.criteriaType,
    required this.criteriaValue,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      rarity: json['rarity'] ?? 'common',
      criteriaType: json['criteriaType'] ?? '',
      criteriaValue: (json['criteriaValue'] as num?)?.toInt() ?? 0,
    );
  }
}
