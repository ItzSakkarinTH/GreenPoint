class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final String shopId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.imageUrl,
    required this.shopId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: json['id'] ?? json['_id'] ?? json['productId'] ?? '',
      name: json['name'] ?? json['productName'] ?? json['title'] ?? '',
      description: json['description'] ?? json['detail'],
      price: parsePrice(json['price'] ?? json['productPrice']),
      stock: (json['stock'] ?? json['quantity'] ?? 0) is int 
          ? (json['stock'] ?? json['quantity'] ?? 0) 
          : int.tryParse((json['stock'] ?? json['quantity'] ?? 0).toString()) ?? 0,
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['imgUrl'],
      shopId: json['shopId'] ?? json['storeId'] ?? json['shop'] ?? '',
    );
  }
}
