class Reward {
  final String id;
  final String name;
  final String? description;
  final int pointsRequired;
  final String? imageUrl;
  final String shopId;
  final int stock;

  Reward({
    required this.id,
    required this.name,
    this.description,
    required this.pointsRequired,
    this.imageUrl,
    required this.shopId,
    this.stock = 999,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      pointsRequired: json['pointsRequired'] ?? json['points'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['image'],
      shopId: json['shopId']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 999,
    );
  }
}
