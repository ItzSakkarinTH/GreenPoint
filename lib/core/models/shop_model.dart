class Shop {
  final String shopId;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? imageUrl;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  Shop({
    required this.shopId,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.imageUrl,
    this.isActive = true,
    this.latitude,
    this.longitude,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    final location = json['location'];
    if (location != null && location['coordinates'] != null) {
      lng = (location['coordinates'][0] as num?)?.toDouble();
      lat = (location['coordinates'][1] as num?)?.toDouble();
    }
    return Shop(
      shopId: json['shopId'] ?? json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      latitude: lat,
      longitude: lng,
    );
  }
}
