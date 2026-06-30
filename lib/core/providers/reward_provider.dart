import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import 'package:greenpoint/core/providers/shop_provider.dart';

final shopRewardsProvider = FutureProvider.autoDispose.family<List<Reward>, String>((ref, shopId) async {
  final apiService = ref.watch(apiServiceProvider);
  
  final response = await apiService.getRewards(shopId);
  return (response as List).map((e) => Reward.fromJson(e)).toList();
});
