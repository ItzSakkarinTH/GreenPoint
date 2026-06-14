import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greenpoint/core/network/api_service.dart';
import 'package:greenpoint/core/models/shop_model.dart';
import 'package:greenpoint/core/models/product_model.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final responseData = await apiService.getShops();
  
  final list = responseData is Map 
      ? (responseData['data'] ?? responseData['shops'] ?? []) 
      : (responseData as List);
      
  return (list as List).map((json) => Shop.fromJson(json)).toList();
});

final selectedShopIdProvider = NotifierProvider<SelectedShopNotifier, String?>(() {
  return SelectedShopNotifier();
});

class SelectedShopNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? value) => super.state = value;
}

final productsProvider = FutureProvider.family<List<Product>, String>((ref, shopId) async {
  final apiService = ref.watch(apiServiceProvider);
  final responseData = await apiService.getProducts(shopId);
  
  // Handle wrapped responses (e.g., { "data": [...] } or { "products": [...] })
  final list = responseData is Map 
      ? (responseData['data'] ?? responseData['products'] ?? []) 
      : (responseData as List);
      
  return (list as List).map((json) => Product.fromJson(json)).toList();
});

// ดึงพิกัดตำแหน่งปัจจุบันของผู้ใช้
final userLocationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  // ตรวจสอบว่าเปิดระบบระบุตำแหน่งหรือไม่
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return null;
  } 

  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  } catch (e) {
    return await Geolocator.getLastKnownPosition();
  }
});

// ค้นหาร้านค้าใกล้เคียงตามพิกัดและรัศมี (ค่าเริ่มต้น 5 กิโลเมตร)
final nearbyShopsProvider = FutureProvider.family<List<Shop>, double>((ref, radius) async {
  final apiService = ref.watch(apiServiceProvider);
  final locationAsync = ref.watch(userLocationProvider);
  
  // พิกัดเริ่มต้น (Siam Square) หาก GPS ไม่พร้อมใช้งาน
  double lat = 13.7469;
  double lng = 100.5393;
  
  final position = locationAsync.asData?.value;
  if (position != null) {
    lat = position.latitude;
    lng = position.longitude;
  }
  
  final responseList = await apiService.getNearbyShops(lat, lng, radius: radius.toInt());
  return responseList.map((json) => Shop.fromJson(json)).toList();
});
