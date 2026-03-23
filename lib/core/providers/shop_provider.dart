import 'package:flutter_riverpod/flutter_riverpod.dart';
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
