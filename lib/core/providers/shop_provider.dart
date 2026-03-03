import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../models/shop_model.dart';

import '../models/product_model.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getShops();
  return data.map((json) => Shop.fromJson(json)).toList();
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
  final data = await apiService.getProducts(shopId);
  return data.map((json) => Product.fromJson(json)).toList();
});
