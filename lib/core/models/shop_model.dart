class Shop {
  final String shopId;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? imageUrl;
  final bool isActive;

  Shop({
    required this.shopId,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.imageUrl,
    this.isActive = true,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      shopId: json['shopId'] ?? json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}
