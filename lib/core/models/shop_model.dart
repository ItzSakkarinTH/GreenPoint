class Shop {
  final String shopId;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String imageUrl;
  final String logoUrl;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  Shop({
    required this.shopId,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.imageUrl = '',
    this.logoUrl = '',
    this.isActive = true,
    this.latitude,
    this.longitude,
  });

  // ดึงรูปโปรไฟล์โดยเช็คเงื่อนไข fallback
  String get profileImageUrl {
    if (logoUrl.isNotEmpty) {
      return logoUrl;
    } else if (imageUrl.isNotEmpty) {
      return imageUrl;
    } else {
      return 'https://via.placeholder.com/150?text=Shop'; // รูปแทนกรณีไม่มีทั้งคู่
    }
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    // Parse location coordinates: [longitude, latitude]
    final location = json['location'];
    double? lat;
    double? lng;
    if (location != null && location['coordinates'] is List) {
      final coords = location['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }
    // Fallback to flat fields
    lat ??= (json['latitude'] as num?)?.toDouble();
    lng ??= (json['longitude'] as num?)?.toDouble();

    return Shop(
      shopId: json['shopId'] ?? json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      imageUrl: json['imageUrl'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      latitude: lat,
      longitude: lng,
    );
  }
}
