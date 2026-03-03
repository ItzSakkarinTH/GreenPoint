import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_provider.dart'; // ใช้ apiServiceProvider จากที่นี่
import '../models/user_model.dart';

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getUserProfile();
  
  return UserProfile(
    name: data['name'] ?? 'Unknown User',
    level: data['level'] ?? 1,
    currentXp: data['currentXp'] ?? 0,
    maxXp: data['maxXp'] ?? 100,
    plasticReduced: data['plasticReduced'] ?? 0,
  );
});

final historyProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getTransactionHistory();
  
  return (data as List).map((item) => Transaction(
    id: item['id']?.toString() ?? '',
    title: item['title'] ?? 'กิจกรรมรักษ์โลก',
    date: item['date'] ?? '-',
    points: item['points'] ?? 0,
    isNegative: item['isNegative'] ?? false,
  )).toList();
});
