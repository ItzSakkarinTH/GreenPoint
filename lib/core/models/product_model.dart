class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String shopId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.shopId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      shopId: json['shopId'] ?? '',
    );
  }
}
