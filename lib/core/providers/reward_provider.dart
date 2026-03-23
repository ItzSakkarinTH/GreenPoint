import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import 'shop_provider.dart';

final shopRewardsProvider = FutureProvider.autoDispose.family<List<Reward>, String>((ref, shopId) async {
  final apiService = ref.watch(apiServiceProvider);
  
  // ในระหว่างรอ Backend จริง สามารถ Mock ข้อมูลตามรูปภาพได้
  try {
    final response = await apiService.getRewards(shopId);
    return (response as List).map((e) => Reward.fromJson(e)).toList();
  } catch (e) {
    // Mock ข้อมูลสำหรับร้าน Cha-ji Coffee (หรือร้านอื่นๆ เพื่อทดสอบ)
    return [
      Reward(
        id: '1',
        name: 'แก้วพกพา',
        pointsRequired: 1200,
        shopId: shopId,
        imageUrl: 'https://img.freepik.com/premium-vector/reusable-coffee-cup-icon_414330-153.jpg',
      ),
      Reward(
        id: '2',
        name: 'ถุงผ้ารักโลก',
        pointsRequired: 900,
        shopId: shopId,
        imageUrl: 'https://img.freepik.com/premium-vector/tote-bag-with-leaf-logo-eco-friendly-concept_114835-139.jpg',
      ),
      Reward(
        id: '3',
        name: 'กระเป๋าดินสอ',
        pointsRequired: 300,
        shopId: shopId,
      ),
    ];
  }
});
